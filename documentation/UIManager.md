# UIManager

### Description
The UIManager is meant to handle all UIs without knowing what exactly is inside the UI. This manager provides a central point for all the UIs to talk to, so that there are no interfering UIs.

### Features include:
* Queueing UI.
* Going back to the previous UI.
* Capturing and releasing the mouse cursor.
* Dismissing UI.
* Loading level.
* Quiting.

### Functions
> **void RegisterBaseUI ( Node node )**  
You can select a node in the tree to be the parent of all the UIs. The UIManager wil handle the adding and removing of the UI. This function should be used in ``_ready``.
>
> **void NextUI ( String path )**  
A new instance of a UI is made and added to the tree. Resource should be a path like ``"res://UI/menu.tscn"`` for example.
>
> **bool CanGoBack ( )**  
Returns true when there is a previous UI availble to which the UIManager can return.
>
> **void Back ( ):**  
The UIManager will go back to the previous UI if one is available. It will ignore this when the history queue is empty.
>
> **void DismissUI ( ):**  
The displayed UI will be removed from the tree. If there are any future queued UIs or UIs in the history queue it will go to that.
>
> **void ClearUI ( ):**  
The current UI will be removed and all queued UIs will be ignored.
>
> **bool RequestFocus ( ):**  
Returns true if there currently is no UI that has focus. Use ``ReleaseFocus`` when done.
>
> **void ReleaseFocus ( ):**  
Once focus is no longer needed it can be released, making character controls work again for example.


### Example

Before a UI can be added to the UIManager a base needs to be registered. This base is the parent node of the UI. The UIManager handles the ``add_child`` and ``remove_child``, so there is no need to do this manually.

```gdscript
var ui_resource = "res://assets/my_ui.tscn"
var added_ui = false

func _ready():
	UIManager.RegisterBaseUI(self)
```

Once the base has been registered, then the UI can be added at will. In this example a menu will be toggled on and off when a key is pressed. The menu script needs to keep track of adding or removing the UI by using a boolean.

```gdscript
func _input(event):
	if event.is_action_pressed("ui_button"):
		if added_ui:
			UIManager.ClearUI()
			added_ui = false
		elif UIManager.RequestFocus():
			UIManager.SwitchUI(ui_resource)
			added_ui = true
```

## UIElement

### Description
To quickly hook up buttons and other UI elements the UIElement script can be used. This script needs to be attached to a node, and then configured using the inspector. The script uses the functions in the UIManager.

![Export Variables](/ui_element_export.png)

### UIEvents

> **Back**  
Go to the previous UI.  
> **Create UI**  
Show a new UI using either the path or the PackedScene variable.  
> **Queue UI**  
> **Set Setting**  
> **Dismiss**  
> **Load Level**  
> **Join Server**  
> **Run Locally**  
