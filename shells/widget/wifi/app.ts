import app from "ags/gtk4/app"
import WifiWindow from "./windows/WifiWindow"

app.start({
  instanceName: "wifi",
  main() {
    WifiWindow() 
  },
})
