import { Gtk } from "ags/gtk4"
import Header from "../components/WifiHeader"
import NetworkList from "../components/NetworkList"

export default function WifiWindow() {
  return (
    <window
      name="wifi"
      visible={true}
    >
      <box orientation={Gtk.Orientation.VERTICAL}>
      <Header />
      <NetworkList />
      </box>
    </window>
  )
}
