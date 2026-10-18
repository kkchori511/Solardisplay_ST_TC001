# @name Weather
# @icons sunny, clear_night, partly_day, partly_night, cloudy, clear_to_cloudy, rain_to_clear, drizzle, rain, shower, thunder, snow, sleet, fog
# @config kma_key text "기상청 인증키" default="" maxlen=100
#
# 기상청 초단기 날씨(김포시 마산동, 격자 54/128)를 가져와 아이콘, 기온, 우산, 강수확률을 표시한다.
# 매시 50분에 한 번 갱신한다 (초단기실황은 40분, 초단기예보는 45분 이후 제공).
# 응답이 8KB를 넘으므로 필요한 항목(SKY, PTY, POP, LGT)만 find/keep으로 골라 받는다.
# 화면: [날씨 아이콘 0-7] 기온 ... 우산 확률(오른쪽 끝)

import json
import math

class Weather
  var key, busy, step, wait_s, retry_in, last_hour_key, age_s, ready
  var cat, times, vals, ncst_temp, ncst_pty
  var icon_name, temp_text, pop_text, temp_x, pop_x, umb_x, umb

  def init()
    self.key = store.get("kma_key", "")
    self.busy = false
    self.step = 0
    self.wait_s = 0
    self.retry_in = 0
    self.last_hour_key = -1
    self.age_s = 0
    self.ready = false
    self.cat = ""
    self.times = []
    self.vals = {}
    self.ncst_temp = nil
    self.ncst_pty = 0
    self.icon_name = "cloudy"
    self.temp_text = ""
    self.pop_text = ""
    self.temp_x = 9
    self.pop_x = 25
    self.umb_x = 19
    # 우산 모양 [열, 행]
    self.umb = [[1,1],[2,1],[3,1],[0,2],[1,2],[2,2],[3,2],[4,2],[2,3],[2,4],[1,5],[0,5]]
  end

  # ---------- 날짜/시간 계산 ----------

  def days_in_month(y, m)
    if m == 2
      if (y % 4 == 0 && y % 100 != 0) || y % 400 == 0
        return 29
      end
      return 28
    end
    if m == 4 || m == 6 || m == 9 || m == 11
      return 30
    end
    return 31
  end

  def day_of_year()
    var doy = day()
    var m = 1
    while m < month()
      doy += self.days_in_month(year(), m)
      m += 1
    end
    return doy
  end

  # 낮/밤: 김포의 일출/일몰을 날짜로 근사
  def is_day()
    var h = hour() + minute() / 60.0
    var dl = 12 + 2.45 * math.cos(2 * math.pi * (self.day_of_year() - 172) / 365.0)
    return h >= 12.55 - dl / 2 && h < 12.55 + dl / 2
  end

  # 지금 또는 한 시간 전의 [YYYYMMDD, 시]
  def shifted(back)
    var y = year()
    var m = month()
    var d = day()
    var h = hour()
    if back
      h -= 1
      if h < 0
        h = 23
        d -= 1
        if d < 1
          m -= 1
          if m < 1
            m = 12
            y -= 1
          end
          d = self.days_in_month(y, m)
        end
      end
    end
    return [format("%04d%02d%02d", y, m, d), h]
  end

  # ---------- 기상청 요청 ----------

  def base_url(api)
    return "https://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/" + api + "?serviceKey=" + self.key + "&pageNo=1&dataType=JSON&nx=54&ny=128"
  end

  def fetch()
    self.busy = true
    self.wait_s = 0
    self.step = 0
    self.vals = {}
    self.times = []
    self.request_next()
  end

  def request_next()
    if self.step == 0
      # 초단기실황: 매시 정각 기준, 40분 이후 제공
      var b = self.shifted(minute() < 40)
      var url = self.base_url("getUltraSrtNcst") + "&numOfRows=10&base_date=" + b[0] + "&base_time=" + format("%02d00", b[1])
      http.get(url, / body, st -> self.on_ncst(body, st))
      return
    end
    # 초단기예보: 매시 30분 기준, 45분 이후 제공. 항목별로 필요한 부분만 받는다.
    var cats = ["SKY", "PTY", "POP", "LGT"]
    self.cat = cats[self.step - 1]
    var b = self.shifted(minute() < 45)
    var url = self.base_url("getUltraSrtFcst") + "&numOfRows=100&base_date=" + b[0] + "&base_time=" + format("%02d30", b[1])
    http.get(url, / body, st -> self.on_cat(body, st), {'find': '"category":"' + self.cat + '"', 'keep': 1100})
  end

  def on_ncst(body, st)
    if body == nil || st != 200
      log("weather: 실황 실패 status=" + str(st))
      self.finish(false)
      return
    end
    var data = json.load(body)
    var items = nil
    if isinstance(data, map)
      var r = data.find("response")
      if isinstance(r, map)
        var bd = r.find("body")
        if isinstance(bd, map)
          var it = bd.find("items")
          if isinstance(it, map)
            items = it.find("item")
          end
        end
      end
    end
    if !isinstance(items, list)
      log("weather: 실황 응답 형식 오류")
      self.finish(false)
      return
    end
    self.ncst_temp = nil
    self.ncst_pty = 0
    for x: items
      var c = x.find("category")
      if c == "T1H"
        self.ncst_temp = num(x.find("obsrValue"))
      elif c == "PTY"
        self.ncst_pty = int(num(x.find("obsrValue")))
      end
    end
    if self.ncst_temp == nil
      log("weather: 기온 없음")
      self.finish(false)
      return
    end
    self.step = 1
    self.request_next()
  end

  def on_cat(body, st)
    if body == nil || st != 200
      log("weather: " + self.cat + " 실패 status=" + str(st))
      self.finish(false)
      return
    end
    var pat = '"category":"' + self.cat + '","fcstDate":"\\d+","fcstTime":"\\d+","fcstValue":"[^"]*"'
    var rows = re.matchall(pat, body)
    var m = {}
    var times = []
    if rows != nil
      for r: rows
        var g = re.search('"fcstDate":"(\\d+)","fcstTime":"(\\d+)","fcstValue":"([^"]*)"', r)
        if g != nil
          var k = g[1] + g[2]
          times.push(k)
          m[k] = num(g[3])
        end
      end
    end
    if self.cat == "SKY"
      if size(times) == 0
        log("weather: SKY 데이터 없음")
        self.finish(false)
        return
      end
      self.times = times
    end
    self.vals[self.cat] = m
    self.step += 1
    if self.step > 4
      self.finish(true)
    else
      self.request_next()
    end
  end

  def finish(ok)
    self.busy = false
    if ok
      self.last_hour_key = day() * 100 + hour()
      self.age_s = 0
      self.retry_in = 0
      self.compute()
      log("weather: 갱신 " + self.icon_name + " " + self.temp_text + " " + self.pop_text)
    else
      self.retry_in = 300
    end
  end

  # ---------- 아이콘과 표시 값 ----------

  def val(cat, t, dflt)
    var m = self.vals.find(cat)
    if m != nil
      var v = m.find(t)
      if v != nil
        return v
      end
    end
    return dflt
  end

  def precip_icon(pty)
    if pty == 4
      return "shower"
    elif pty == 5
      return "drizzle"
    elif pty == 2 || pty == 6
      return "sleet"
    elif pty == 3 || pty == 7
      return "snow"
    end
    return "rain"
  end

  # 지금 정각 이후 예보 시각 목록
  def upcoming()
    var now_key = format("%04d%02d%02d%02d00", year(), month(), day(), hour())
    var out = []
    for t: self.times
      if t >= now_key
        out.push(t)
      end
    end
    if size(out) == 0 && size(self.times) > 0
      out.push(self.times[-1])
    end
    return out
  end

  def pick_icon(fc)
    var day_time = self.is_day()
    var t1 = fc[0]
    var pty = self.ncst_pty
    if pty == 0
      pty = int(self.val("PTY", t1, 0))
    end

    if self.val("LGT", t1, 0) > 0
      return "thunder"
    end

    if pty != 0
      # 비온뒤갬: 지금은 비(눈 제외)지만 이후 3시간 이상 비가 없고 흐리지 않음
      if day_time && (pty == 1 || pty == 4 || pty == 5) && size(fc) >= 4
        var dry = true
        var i = 1
        while i < size(fc)
          if self.val("PTY", fc[i], 0) != 0 || self.val("SKY", fc[i], 3) == 4
            dry = false
          end
          i += 1
        end
        if dry
          return "rain_to_clear"
        end
      end
      return self.precip_icon(pty)
    end

    var sky = int(self.val("SKY", t1, 3))
    if sky == 1
      # 맑은뒤흐림: 지금은 맑지만 이후 3시간 안에 흐려짐
      var i = 1
      while i < size(fc) && i < 4
        if self.val("SKY", fc[i], 1) == 4
          if day_time
            return "clear_to_cloudy"
          end
          return "partly_night"
        end
        i += 1
      end
      if day_time
        return "sunny"
      end
      return "clear_night"
    elif sky == 3
      if day_time
        return "partly_day"
      end
      return "partly_night"
    end
    return "cloudy"
  end

  # 데이터가 바뀌었거나 낮/밤이 바뀔 수 있을 때 표시 값을 다시 계산
  def compute()
    var fc = self.upcoming()
    if size(fc) == 0 || self.ncst_temp == nil
      return
    end
    self.icon_name = self.pick_icon(fc)
    var temp = int(round(self.ncst_temp))
    var pop = int(round(self.val("POP", fc[0], 0)))
    if pop > 99
      pop = 99
    end
    if pop < 0
      pop = 0
    end
    self.temp_text = str(temp)
    self.pop_text = str(pop)
    # 기온이 3글자(-10 이하)면 우산과 겹치므로 한 칸 왼쪽으로
    if size(self.temp_text) >= 3
      self.temp_x = 8
    else
      self.temp_x = 9
    end
    self.pop_x = 32 - (4 * size(self.pop_text) - 1)
    self.umb_x = self.pop_x - 1 - 5
    self.ready = true
  end

  # ---------- 앱 훅 ----------

  def loop()
    self.age_s += 1
    if self.busy
      self.wait_s += 1
      if self.wait_s > 120
        self.busy = false
        self.retry_in = 300
      end
      return
    end
    if self.key == "" || hour() < 0
      return
    end
    if self.retry_in > 0
      self.retry_in -= 1
      if self.retry_in == 0
        self.fetch()
      end
      return
    end
    var hk = day() * 100 + hour()
    if self.last_hour_key < 0 || (minute() >= 50 && hk != self.last_hour_key)
      self.fetch()
      return
    end
    # 낮/밤이나 시간 경과로 아이콘이 바뀔 수 있어 1분마다 다시 계산
    if self.ready && second() == 0
      self.compute()
    end
  end

  def should_show()
    if self.key == ""
      return true
    end
    return self.ready && self.age_s < 10800
  end

  def duration()
    return 5000
  end

  def draw()
    clear()
    if self.key == ""
      text(1, 6, "NO KEY", 0xFF0000)
      return
    end
    if !icon(self.icon_name, 0, 0)
      rect_fill(0, 0, 8, 8, 0x222222)
    end
    text(self.temp_x, 6, self.temp_text, 0xFFFFFF)
    for p: self.umb
      pixel(self.umb_x + p[0], p[1], 0x3C8CFF)
    end
    text(self.pop_x, 6, self.pop_text, 0x3C8CFF)
  end
end

return Weather()
