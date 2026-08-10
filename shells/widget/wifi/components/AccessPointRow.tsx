import AstalNetwork from "gi://AstalNetwork?version=0.1"
import { createBinding, createComputed } from "ags"
import { connectToAp, disconnect, wifi } from "../services/wifi"

export interface AccessPointRowProps {
  ap: AstalNetwork.AccessPoint
}

export default function AccessPointRow({ ap }: AccessPointRowProps) {
  const ssid = createBinding(ap, "ssid")
  const strength = createBinding(ap, "strength")
  const icon = createBinding(ap, "iconName")
  const active = createBinding(wifi, "activeAccessPoint").as(
    (activeAp) => activeAp?.bssid !== undefined && activeAp?.bssid === ap.bssid,
  )

  return (
    <button
      class={active.as((isActive) => (isActive ? "ap-row active" : "ap-row"))}
      onClicked={() => (active.peek() ? disconnect() : connectToAp(ap))}
      tooltipText={ssid}
    >
      <box spacing={12}>
        <icon icon={icon.as((name) => name || "network-wireless-symbolic")} />
        <label
          class="ap-ssid"
          hexpand={true}
          halign="start"
          ellipsize="end"
          label={ssid.as((name) => (name ? name : "(hidden network)"))}
        />
        <box spacing={4}>
          <label
            class="ap-state"
            label="Connected"
            visible={active}
          />
          <icon
            name="network-wireless-encrypted-symbolic"
            visible={createComputed(() => !active.peek() && ap.requiresPassword)}
          />
          <label class="ap-strength" label={strength.as((s) => `${s}%`)} />
        </box>
      </box>
    </button>
  )
}