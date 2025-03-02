---@meta _

---@class mineOS.GUI
local GUI = {}

---@alias GUI.Horizontal_alignment 
---|`GUI.ALIGNMENT_HORIZONTAL_LEFT`
---|`GUI.ALIGNMENT_HORIZONTAL_CENTER`
---|`GUI.ALIGNMENT_HORIZONTAL_RIGHT`

---@alias GUI.Vertical_alignment
---|`GUI.ALIGNMENT_VERTICAL_TOP`
---|`GUI.ALIGNMENT_VERTICAL_CENTER`
---|`GUI.ALIGNMENT_VERTICAL_BOTTOM`

---@alias GUI.Direction
---|`GUI.DIRECTION_HORIZONTAL` 
---|`GUI.DIRECTION_VERTICAL`

---@alias GUI.SIZE_POLICY
---|`GUI.SIZE_POLICY_ABSOLUTE`
---|`GUI.SIZE_POLICY_RELATIVE`

---@alias GUI.IO_Mode
---|`GUI.IO_MODE_SAVE`
---|`GUI.IO_MODE_FILE`
---|`GUI.IO_MODE_DIRECTORY`

---@class GUI.object
---@field horizontalAlignment GUI.Horizontal_alignment
---@field verticalAlignment GUI.Vertical_alignment
---@field ignoresCapturedObject boolean
---@field parent GUI.container
---@field layoutRow? number
---@field layoutColumn? number
---@field eventHandler fun(workspace:GUI.workspace, object:GUI.object, e1:string, ...)
local object = {}

---Creates a new GUI object.
---@param x number Object coordinate by x-axis
---@param y number Object coordinate by y-axis
---@param width number Object width
---@param height number Object height
---@return GUI.object
function GUI.object(x, y, width, height)
end

---Current screen rendering coordinate of object by x-axis.
---@type number
object.x = nil

---Current screen rendering coordinate of object by y-axis.
---@type number
object.y = nil

---Object width.
---@type number
object.width = nil

---Object height.
---@type number
object.height = nil

---Whether the object is hidden.
---@type boolean
object.hidden = nil

---Whether the object is disabled.
---@type boolean
object.disabled = nil

---Whether screen events like touch/drag should be blocked or pass through object to deeper levels of the hierarchy.
---@type boolean
object.blockScreenEvents = true
---Reference to current workspace which has the topmost position in the hierarchy of objects tree.
---@type GUI.workspace
object.workspace = nil

---Reference to the parent container of the object.
---@type GUI.container
object.parent = nil

---Local position on the x-axis in the parent container.
---@type number
object.localX = nil

---Local position on the y-axis in the parent container.
---@type number
object.localY = nil

---Get the index of this object in the parent container (iterative method).
---@return number
function object:indexOf()
end

---Move the object "back" in the container children hierarchy.
---@return nil
function object:moveForward()
end

---Move the object "forward" in the container children hierarchy.
---@return nil
function object:moveBackward()
end

---Move the object to the end of the container children hierarchy.
---@return nil
function object:moveToFront()
end

---Move the object to the beginning of the container children hierarchy.
---@return nil
function object:moveToBack()
end

---Remove this object from the parent container. Roughly speaking, this is a convenient way of self-destruction.
---@return nil
function object:remove()
end

---Add an animation to this object.
---@param frameHandler fun(animation:GUI.animation) The function to handle each frame of the animation
---@param onFinish fun(animation:GUI.animation) The function to call when the animation finishes
---@return GUI.animation
function object:addAnimation(frameHandler, onFinish)
end

---Main method that is called to render this object to the screen buffer. It can be defined by the user in any convenient way.
---@generic K
---@param object K
---@return K
function object.draw(object)
end

---@param workspace GUI.workspace
---@param object GUI.object
---@param ... unknown
function object.eventHandler(workspace, object, ...) end

-------------------------------------------------------------------------------------------------------------------------

---@class GUI.container : GUI.object
local container = {}

---Creates a new container.
---@param x number Container's coordinate by x-axis
---@param y number Container's coordinate by y-axis
---@param width number Container's width
---@param height number Container's height
---@return GUI.container
function GUI.container(x, y, width, height)
end

---Table that contains all child objects of this container.
---@type GUI.object[]
container.children = {}



---Remove all child elements of the container.
---@param fromIndex? number The starting index from which to remove child elements (optional)
---@param toIndex? number The ending index to which to remove child elements (optional)
---@return nil
function container:removeChildren(fromIndex, toIndex)
end

-------------------------------------------------------------------------------------------------------------------------

--[[---@class GUI.workspace : GUI.container
local workspace = {}

---Creates a new workspace, which is a full screen container that can handle computer events.
---@param x? number Optional coordinate by x-axis
---@param y? number Optional coordinate by y-axis
---@param width? number Optional width
---@param height? number Optional height
---@return GUI.workspace
function GUI.workspace(x, y, width, height)
end

---Reference to the currently captured object. Used for exclusive event processing.
---@type table|nil
workspace.capturedObject = nil

---A reference to the currently focused object. Used mostly in windows and text fields.
---@type table|nil
workspace.focusedObject = nil

---Run the event processing for this container and analyze events for all its child objects.
---@param delay? number Optional delay parameter similar to computer.pullSignal
---@return nil
function workspace:start(delay)
end

---Stop processing events for this container.
---@return nil
function workspace:stop()
end

---Draw every child object of workspace to the screen buffer and render changed pixels to the physical computer screen.
---@param force? boolean Optional argument to force drawing all pixels, not just changed ones
---@return nil
function workspace:draw(force)
end]]

-------------------------------------------------------------------------------------------------------------------------

---@class GUI.panel : GUI.object
local panel = {}

---Creates a new panel object.
---@param x number Panel coordinate by x-axis
---@param y number Panel coordinate by y-axis
---@param width number Panel width
---@param height number Panel height
---@param color number Panel color
---@param transparency? number Optional transparency of the panel
---@return GUI.panel
function GUI.panel(x, y, width, height, color, transparency)
end

---Panel coordinate by x-axis.
---@type integer
panel.x = 0

---Panel coordinate by y-axis.
---@type integer
panel.y = 0

---Panel width.
---@type integer
panel.width = 0

---Panel height.
---@type integer
panel.height = 0

---Panel color.
---@type integer
panel.color = 0

---Optional transparency of the panel.
---@type integer
panel.transparency = 0

-------------------------------------------------------------------------------------------------------------------------

---@class GUI.label : GUI.object
local label = {}



---Choose a text display option for label boundaries.
---@param horizontalAlignment GUI.Horizontal_alignment Horizontal alignment option
---@param verticalAlignment GUI.Vertical_alignment Vertical alignment option
---@return GUI.label
function label:setAlignment(horizontalAlignment, verticalAlignment)
end
label:setAlignment(GUI.ALIGNMENT_VERTICAL_TOP, GUI.ALIGNMENT_VERTICAL_TOP)
-------------------------------------------------------------------------------------------------------------------------

---@class GUI.image : GUI.object
local image = {}

---Creates a new image object.
---@param x number Object coordinate by x-axis
---@param y number Object coordinate by y-axis
---@param loadedImage table The image that was loaded by image.load() method
---@return GUI.image
function GUI.image(x, y, loadedImage)
end

---Table with pixel data of loaded image.
---@type table
image.image = {}

-------------------------------------------------------------------------------------------------------------------------

---@class GUI.button : GUI.pressable
local button = {}

---Creates a new button object.
---@param x number Object coordinate by x-axis
---@param y number Object coordinate by y-axis
---@param width number Object width
---@param height number Object height
---@param buttonColor number Object default background color
---@param textColor number Object default text color
---@param buttonPressedColor number Object pressed background color
---@param textPressedColor number Object pressed text color
---@param text string Object text
---@return GUI.button
function GUI.button(x, y, width, height, buttonColor, textColor, buttonPressedColor, textPressedColor, text)
end

---Creates a new button object.
---@param x number Object coordinate by x-axis
---@param y number Object coordinate by y-axis
---@param width number Object width
---@param height number Object height
---@param buttonColor number Object default background color
---@param textColor number Object default text color
---@param buttonPressedColor number Object pressed background color
---@param textPressedColor number Object pressed text color
---@param text string Object text
---@return GUI.button
function GUI.framedButton(x, y, width, height, buttonColor, textColor, buttonPressedColor, textPressedColor, text)
end

---Creates a new button object.
---@param x number Object coordinate by x-axis
---@param y number Object coordinate by y-axis
---@param width number Object width
---@param height number Object height
---@param buttonColor number Object default background color
---@param textColor number Object default text color
---@param buttonPressedColor number Object pressed background color
---@param textPressedColor number Object pressed text color
---@param text string Object text
---@return GUI.button
function GUI.roundedButton(x, y, width, height, buttonColor, textColor, buttonPressedColor, textPressedColor, text)
end

---Creates a new button object.
---@param x number Object coordinate by x-axis
---@param y number Object coordinate by y-axis
---@param width number Object width
---@param height number Object height
---@param buttonColor number Object default background color
---@param textColor number Object default text color
---@param buttonPressedColor number Object pressed background color
---@param textPressedColor number Object pressed text color
---@param text string Object text
---@return GUI.button
function GUI.adaptiveButton(x, y, width, height, buttonColor, textColor, buttonPressedColor, textPressedColor, text)
end

---Creates a new button object.
---@param x number Object coordinate by x-axis
---@param y number Object coordinate by y-axis
---@param width number Object width
---@param height number Object height
---@param buttonColor number Object default background color
---@param textColor number Object default text color
---@param buttonPressedColor number Object pressed background color
---@param textPressedColor number Object pressed text color
---@param text string Object text
---@return GUI.button
function GUI.adaptiveFramedButton(x, y, width, height, buttonColor, textColor, buttonPressedColor, textPressedColor, text)
end

---Creates a new button object.
---@param x number Object coordinate by x-axis
---@param y number Object coordinate by y-axis
---@param width number Object width
---@param height number Object height
---@param buttonColor number Object default background color
---@param textColor number Object default text color
---@param buttonPressedColor number Object pressed background color
---@param textPressedColor number Object pressed text color
---@param text string Object text
---@return GUI.button
function GUI.adaptiveRoundedButton(x, y, width, height, buttonColor, textColor, buttonPressedColor, textPressedColor, text)
end

---Creates a new button object.
---@param x number Object coordinate by x-axis
---@param y number Object coordinate by y-axis
---@param width number Object width
---@param height number Object height
---@param buttonColor number Object default background color
---@param textColor number Object default text color
---@param buttonPressedColor number Object pressed background color
---@param textPressedColor number Object pressed text color
---@param text string Object text
---@return GUI.button
function GUI.roundedButton(x, y, width, height, buttonColor, textColor, buttonPressedColor, textPressedColor, text)
end

button.animationStarted = true

---This property allows the user to understand whether the button is pressed or not.
---@type boolean
button.pressed = false

---This property is responsible for the mode at which the button behaves like a switch: when pressed, it will change its state to the opposite. The default value is false.
---@type boolean
button.switchMode = false

---This property is responsible for button's color transition animation when it is clicked. The default value is true.
---@type boolean
button.animated = true

---Duration of the animation of the button when the animation is enabled. The default value is 0.2.
---@type number
button.animationDuration = 0.2

---If this method exists, it is called after clicking on the button.
---@param workspace GUI.workspace
---@param button GUI.button
---@param ... any
function button.onTouch(workspace, button, ...)
end

-------------------------------------------------------------------------------------------------------------------------

---@class GUI.actionButtons : GUI.object
local actionButtons = {}

---Creates a new action buttons container.
---@param x number Object coordinate by x-axis
---@param y number Object coordinate by y-axis
---@param fat? boolean The option of drawing buttons with a large size
---@return GUI.actionButtons
function GUI.actionButtons(x, y, fat)
end

---Pointer to a red button object.
---@type table
actionButtons.close = {}

---Pointer to a yellow button object.
---@type table
actionButtons.minimize = {}

---Pointer to a green button object.
---@type table
actionButtons.maximize = {}

-------------------------------------------------------------------------------------------------------------------------

---@class GUI.list : GUI.layout
local list = {}

---Creates a new list object.
---@param x number Object coordinate by x-axis
---@param y number Object coordinate by y-axis
---@param width number Object width
---@param height number Object height
---@param itemSize number Item size by selected direction
---@param spacing number Space between items
---@param backgroundColor number Object background color
---@param textColor number Object text color
---@param alternateBackgroundColor number Object alternate background color
---@param alternateTextColor number Object alternate text color
---@param backgroundSelectedColor number Object selection background color
---@param textSelectedColor number Object selection text color
---@param offsetMode? boolean Optional mode, in which the items size are created based on the pixel offset from their texts
---@return GUI.list
function GUI.list(x, y, width, height, itemSize, spacing, backgroundColor, textColor, alternateBackgroundColor, alternateTextColor, backgroundSelectedColor, textSelectedColor, offsetMode)
end

---Index of currently selected item.
---@type integer
list.selectedItem = 0

---Add new item to object. You can specify .onTouch() function if desired.
---@param text string The text of the item
---@return GUI.button
function list:addItem(text)
end

---Get item by its index.
---@param index integer The index of the item
---@return table item
function list:getItem(index)
end

---Set list items alignment. By default, it's set to GUI.ALIGNMENT_HORIZONTAL_LEFT and GUI.ALIGNMENT_VERTICAL_TOP.
---@param horizontalAlignment GUI.Horizontal_alignment The horizontal alignment
---@param verticalAlignment GUI.Vertical_alignment The vertical alignment
---@return GUI.list
function list:setAlignment(horizontalAlignment, verticalAlignment)
end

---Choose an items display option for List boundaries. The default alignment is left and top.
---@param direction number The direction
---@return GUI.list
function list:setDirection(direction)
end

---Set spacing between List items.
---@param spacing number The spacing
---@return GUI.list
function list:setSpacing(spacing)
end

---Set margin in pixels depending on the current alignment of List.
---@param horizontalMargin number The horizontal margin
---@param verticalMargin number The vertical margin
---@return GUI.list
function list:setMargin(horizontalMargin, verticalMargin)
end

---Get current margins in pixels of List.
---@return integer row, integer horizontalMargin, integer verticalMargin
function list:getMargin()
end

-------------------------------------------------------------------------------------------------------------------------

---@class GUI.contextMenu
local contextMenu = {}

---Adds a new item to the context menu.
---@param text string Item text
---@param disabled boolean If true, the item will not react to mouse clicking
---@param shortcut string Optional shortcut text
---@param color number Optional item color
---@return table item
function contextMenu:addItem(text, disabled, shortcut, color)
end

---Adds a separator to the context menu.
function contextMenu:addSeparator()
end

---Removes an item from the context menu by its index.
---@param index number Item index
---@return table item
function contextMenu:removeItem(index)
end

---Adds a submenu item to the context menu.
---@param text string Item text
---@param disabled boolean If true, the submenu item will not react to mouse clicking
---@return table contextMenu
function contextMenu:addSubMenuItem(text, disabled)
end

---Called after the user selects a menu item or closes the context menu.
---@param selectedIndex number Index of the selected item
function contextMenu.onMenuClosed(selectedIndex)
end

-------------------------------------------------------------------------------------------------------------------------

---@param ... unknown
function GUI.alert(...)
end

-------------------------------------------------------------------------------------------------------------------------

return GUI