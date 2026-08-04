import app from "ags/gtk4/app"

function Bar() {
  return (
    <window visible class="Bar">
      <box>
        Content of the widgets
        <MyButton />
      </box>
    </window>
  )
}

function MyButton() {
  return (
    <button onClicked={self => console.log(self, "clicked")}>
      <label label="Click me!" />
    </button>
  )
}
app.start({
  main() {
    Bar()
  }
})
