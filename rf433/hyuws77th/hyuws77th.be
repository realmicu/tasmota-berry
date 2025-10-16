import webserver
import mqtt

class HyuWS77TH

  static sname = "HYU"
  static version = "1.0.0"
  static trstr = ["Stable", "Up", "Down", ""]
  static trarr = ["", "&uarr; ", "&darr; ", ""]
  static tmout_ms = 300000  # Timeout in ms (5 mins) to stop reporting stale values
  var chan, has_hum
  var raw32
  var label
  var id, bat_ok, trend
  var temp, hum
  var period, last_ms
  var last_json
  var topic

  # INIT
  def init(channel, hum_enabled)
    self.chan = channel
    self.has_hum = hum_enabled ? true : false
    self.raw32 = 0
    self.id = 0
    self.bat_ok = true
    self.trend = 3
    self.temp = 0
    self.hum = 0
    self.period = 0
    self.label = self.sname .. self.chan
    self.last_ms = tasmota.millis()
    var t try t = tasmota.cmd("Topic", true)['Topic'] except .. t = "" end
    self.topic = t ? f"stat/{t}/RFSENSOR" : ""
    tasmota.add_rule(["RfReceived#Data", "RfReceived#Protocol=39", "RfReceived#Bits=36"],
      / values -> self.on_recv_rule(values))
    tasmota.log(self.sname .. ": Hyundai WS Senzor 77" .. (self.has_hum ? "TH" : "") ..
      f" on channel {self.chan}, driver version {self.version}", 2)
  end

  # Display sensor on main page (Tasmota callback)
  def web_sensor()
    if self.raw32 == 0 return end
    var t = tasmota.millis() - self.last_ms
    if t > self.tmout_ms return end
    var l = self.label
    var msg = f"{{s}}{l} ID{{m}}0x{self.id:02X}{{e}}" ..
	      f"{{s}}{l} Temperature{{m}}{self.temp:.1f} &deg;C{{e}}" ..
	      (self.has_hum ? f"{{s}}{l} Humidity{{m}}{self.hum} %{{e}}" : "") ..
	      f"{{s}}{l} Temp. trend{{m}}{self.trarr[self.trend]}{self.trstr[self.trend]}{{e}}" ..
	      f"{{s}}{l} Battery status{{m}}" .. (self.bat_ok ? "Good" : "<span style='color:orange;'>&#x26A0;</span> Low") .. "{e}" ..
	      f"{{s}}{l} Period{{m}}{self.period} sec{{e}}" ..
	      f"{{s}}{l} Last seen{{m}}" .. (t / 1000) .. " sec{e}"
    tasmota.web_send_decimal(msg)
  end

  # Add to Teleperiod message (Tasmota callback)
  def json_append()
    if self.raw32 == 0 return end
    if tasmota.millis() - self.last_ms > self.tmout_ms return end
    var msg = f',"{self.label}":{self.last_json}'
    tasmota.response_append(msg)
  end

  # Publish via MQTT
  def mqtt_publish()
    if self.raw32 == 0 || !self.topic return end
    var payload = f'{{"{self.label}":{self.last_json}}}'
    mqtt.publish(self.topic, payload)
  end

  # Reverse bits in bytes
  def bytes_rev(b)
    var s = size(b)
    var r = bytes(-s)
    var bs = (s << 3) - 1
    for i:0..bs r.setbits(i, 1, b.getbits(bs - i, 1)) end
    return r
  end

  # Get temperature (signed float)
  def get_temp(b)
    var r = self.bytes_rev(b)
    var t = (r[0] << 4) | (r[1] >> 4)
    if (t & 0x800) t |= -1 & ~0xfff end
    return t / 10.0
  end

  # Get humidity (unsigned int 0-100)
  def get_hum(b)
    var r = self.bytes_rev(b)
    return r.geti(0, 1) + 100
  end

  # Get JSON body
  def fmt_json_msg()
    return f'{{"Raw32":"0x{self.raw32:08X}","ID":"0x{self.id:02X}","Channel":{self.chan},"BatteryOK":' ..
      self.bat_ok .. ',"TempTrend":"' .. self.trstr[self.trend] .. f'","Temperature":{self.temp:.1f}' ..
      (self.has_hum ? f',"Humidity":{self.hum}' : "") .. f',"Period":{self.period}}}'
  end

  # Rule to trigger on RfReceived (Tasmota callback)
  def on_recv_rule(values)
    # truncate 36-bit to 32-bit by removing unused checksum in last 4 bits
    var b = bytes(values[0][2..9], -4)
    var ch = (b[0] & 0x0c) >> 2
    if ch != self.chan return end  # exit if different channel
    var ts = tasmota.millis()
    var r = b.get(0, -4)
    if r != self.raw32
      self.id = b[0]
      self.bat_ok = (b[1] & 0x80) ? false : true
      self.trend = (b[1] & 0x60) >> 5
      self.temp = self.get_temp(b[1..2])
      if self.has_hum self.hum = self.get_hum(b[3..3]) end
      self.raw32 = r
    end
    self.period = (ts - self.last_ms) / 1000
    self.last_ms = ts
    self.last_json = self.fmt_json_msg()
    if !self.topic tasmota.log(self.sname .. ": " .. self.last_json, 2) end
    self.mqtt_publish()
  end

end
