import { Gtk } from "ags/gtk4"
import { createBinding } from "ags"
import network, { toggle, scan } from "../services/wifi"

export default function Header() {
    return (
        <box spacing={8}>
            <label label="Wi-Fi" hexpand xalign={0} />

            <button onClicked={scan}>
                <image iconName="view-refresh-symbolic" />
            </button>

            <switch
                active={createBinding(network.wifi, "enabled")}
                onStateSet={() => {
                    toggle()
                    return true
                }}
            />
        </box>
    )
}
