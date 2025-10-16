###################################################
# Example autoexec.be for Hyundai outdoor sensors #
# WS Senzor 77 & WS Senzor 77TH                   #
###################################################

# Load class:
load("/hyuws77th.be")

# Hyundai WS77TH WebSensor+Telemetry (temperature + humidity, channel 1)
var hyu0 = HyuWS77TH(1, true)
# Hyundai WS77 WebSensor+Telemetry (temperature, channel 2)
var hyu1 = HyuWS77TH(2, false)

# Register drivers:
tasmota.add_driver(hyu0)
tasmota.add_driver(hyu1)
