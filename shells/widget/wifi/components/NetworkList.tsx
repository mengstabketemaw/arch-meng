import { Gtk } from "ags/gtk4"
import { createBinding, For, Accessor } from "ags"
import network from "../services/wifi"
import AstalNetwork from "gi://AstalNetwork?version=0.1"

export default function NetworkList() {
	const aps = createBinding(network.wifi, "accessPoints");

	return (
		<box orientation={Gtk.Orientation.VERTICAL}>
			<For each={aps}>
				{(ap) => (<label label={ap.ssid} />)}
			</For>

		</box>)
}
