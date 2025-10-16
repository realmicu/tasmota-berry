import webserver

class CAMERemote

  static sname = "CGR"
  static version = "1.0.0"
  static protocol = 8
  static bits = 12
  static repeats = 8
  static pulse = 420
  static argp = "m_cameremote"

  var lcode, rcode
  var hdr, lname, rname
  var lwarg, rwarg

  # INIT
  def init(header, name_left, code_left, name_right, code_right)
    self.hdr = header
    self.lname = name_left ? name_left : "Left"
    self.lcode = f"0x{code_left:03X}"
    self.lwarg = f"{self.argp}_l_{self.lcode}"
    self.rname = name_right ? name_right : "Right"
    self.rcode = f"0x{code_right:03X}"
    self.rwarg = f"{self.argp}_r_{self.rcode}"
    tasmota.log(f"{self.sname}: CAME Gate Remote WebUI Send Buttons ({self.lcode}|{self.rcode}), driver version {self.version}", 2)
  end

  def rfsend_cmd(code)
    return f'RfSend {{"Data":"{code}","Bits":{self.bits},"Protocol":{self.protocol},"Repeat":{self.repeats},"Pulse":{self.pulse}}}'
  end

  def web_add_main_button()
    if self.hdr
      webserver.content_send("<div style=\"text-align:center;\"><h3>" .. self.hdr .. "</h3></div>")
    end
    webserver.content_send("<table style=\"width:100%\"><tbody><tr>")
    webserver.content_send("<td style=\"width:50%\"><button onclick='la(\"&" .. self.lwarg .. "=1\");'>" .. self.lname .. "</button></td>")
    webserver.content_send("<td style=\"width:50%\"><button onclick='la(\"&" .. self.rwarg .. "=1\");'>" .. self.rname .. "</button></td>")
    webserver.content_send("</tr><tr></tr></tbody></table>")
  end

  def web_sensor()
    if webserver.has_arg(self.lwarg)
      tasmota.cmd(self.rfsend_cmd(self.lcode))
    end
    if webserver.has_arg(self.rwarg)
      tasmota.cmd(self.rfsend_cmd(self.rcode))
    end
  end

end
