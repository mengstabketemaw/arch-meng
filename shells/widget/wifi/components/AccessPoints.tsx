import AstalNetwork from "gi://AstalNetwork?version=0.1"
import { For, createBinding, createComputed } from "ags"
import { wifi } from "../services/wifi"
import AccessPointRow from "./AccessPointRow"

export const AccessPoints = () => {
  const aps = createBinding(wifi, "accessPoints").as((list) =>
    [...list].sort((a, b) => b.strength - a.strength),
  )
  const enabled = createBinding(wifi, "enabled")
  const scanning = createBinding(wifi, "scanning")

  return (
    <box class="ap-list" vertical={true} spacing={2}>
      <For each={aps}>
        {(ap: AstalNetwork.AccessPoint) => <AccessPointRow ap={ap} />}
      </For>
      <label
        class="ap-empty"
        halign="start"
        label={createComputed(() =>
          scanning.peek() ? "Scanning..." : "No networks found",
        )}
        visible={createComputed(() => enabled.peek() && aps.peek().length === 0)}
      />
      <label
        class="ap-empty"
        halign="start"
        label="Turn on Wi-Fi to see networks"
        visible={createComputed(() => !enabled.peek())}
      />
    </box>
  )
}

export default AccessPoints