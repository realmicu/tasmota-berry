############################################
# Example autoexec.be for CAMERemote class #
############################################

# Load class:
load("/cameremote.be")

# Create 2 rows with 2 buttons each:
var came0 = CAMERemote("CAME", "", 0x123, "", 0x456)
var came1 = CAMERemote("", "Start", 0x789, "Stop", 0xABC)

# Register buttons:
tasmota.add_driver(came0)
tasmota.add_driver(came1)
