import AstalNetwork from "gi://AstalNetwork?version=0.1"

const network = AstalNetwork.Network.get_default()

export function scan() {
  return network.wifi.scan();
}

export function toggle() {
  network.wifi.enabled = !network.wifi.enabled
}

export default network
