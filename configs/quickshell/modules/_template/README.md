# Adding a module

1. `cp -r _template ../myfeature` and rename the files.
2. Backend state/processes -> new `Services/MyFeature.qml` singleton
   (`pragma Singleton`, register it in `Services/qmldir`).
3. In `Bar.qml`: add `import "modules/myfeature"`, instantiate the popup
   (`MyPopup { id: myPopup; bar: bar }`), add its id to `allPopups` and
   `anyPopupOpen`, and place `MyPill { bar: bar; popup: myPopup }` in the row.
4. Global windows (toasts/OSD-like) are instantiated from `shell.qml` instead.

Conventions: widgets/popups take `required property var bar`; popups get
positioned by `bar.togglePopupAt(popup, pillItem)`; colors and sizes only
from `Theme`; never talk to a CLI from a widget — put it in the service.
