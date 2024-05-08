---@meta mineOS.GUI

---@class mineOS.GUI
local GUI = {
	ALIGNMENT_HORIZONTAL_LEFT = 1,
	ALIGNMENT_HORIZONTAL_CENTER = 2,
	ALIGNMENT_HORIZONTAL_RIGHT = 3,
	ALIGNMENT_VERTICAL_TOP = 4,
	ALIGNMENT_VERTICAL_CENTER = 5,
	ALIGNMENT_VERTICAL_BOTTOM = 6,
}

---@alias Horizontal_alignment 
---|`GUI.ALIGNMENT_HORIZONTAL_LEFT`
---|`GUI.ALIGNMENT_HORIZONTAL_CENTER`
---|`GUI.ALIGNMENT_HORIZONTAL_RIGHT`

---@alias Vertical_alignment
---|`GUI.ALIGNMENT_VERTICAL_TOP`
---|`GUI.ALIGNMENT_VERTICAL_CENTER`
---|`GUI.ALIGNMENT_VERTICAL_BOTTOM`

---@class GUI.object
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

---Main method that is called to render this object to the screen buffer. It can be defined by the user in any convenient way.
---@return nil
function object:draw()
end

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

---Reference to current workspace which has the topmost position in the hierarchy of objects tree.
---@type table
container.workspace = nil

---Reference to the parent container of the object.
---@type table
container.parent = nil

---Local position on the x-axis in the parent container.
---@type number
container.localX = nil

---Local position on the y-axis in the parent container.
---@type number
container.localY = nil

---Get the index of this object in the parent container (iterative method).
---@return number
function container:indexOf()
end

---Move the object "back" in the container children hierarchy.
---@return nil
function container:moveForward()
end

---Move the object "forward" in the container children hierarchy.
---@return nil
function container:moveBackward()
end

---Move the object to the end of the container children hierarchy.
---@return nil
function container:moveToFront()
end

---Move the object to the beginning of the container children hierarchy.
---@return nil
function container:moveToBack()
end

---Remove this object from the parent container. Roughly speaking, this is a convenient way of self-destruction.
---@return nil
function container:remove()
end

---Add an animation to this object.
---@param frameHandler function The function to handle each frame of the animation
---@param onFinish function The function to call when the animation finishes
---@return table animation
function container:addAnimation(frameHandler, onFinish)
end

---An optional method for handling system events, called by the parent container handler.
---@param workspace table The container's workspace
---@param object table The object under consideration
---@vararg ... eventData
function container.eventHandler(workspace, object, ...)
end

---Table that contains all child objects of this container.
---@type table
container.children = {}

---Add specified object to the container as a child.
---@param child table The object to add as a child
---@param atIndex? number The index at which to add the child in the container's children table
---@return table The added child object
function container:addChild(child, atIndex)
end

---Remove all child elements of the container.
---@param fromIndex? number The starting index from which to remove child elements (optional)
---@param toIndex? number The ending index to which to remove child elements (optional)
---@return nil
function container:removeChildren(fromIndex, toIndex)
end

-------------------------------------------------------------------------------------------------------------------------

---@class GUI.workspace : GUI.container
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
end

-------------------------------------------------------------------------------------------------------------------------

---@class GUI.animation
local animation = {}

---A pointer to the widget which contains this animation.
---@type table
animation.object = nil

---Current animation playback position. It is always in [0.0; 1.0] range, where 0.0 is animation starting and 1.0 is animation ending.
---@type number
animation.position = nil

---Start animation playback. During animation playback, the workspace handling events will temporarily handle events with maximum available speed.
---@return nil
function animation:start()
end

---Stop animation playback.
---@return nil
function animation:stop()
end

---Remove animation from its widget.
---@return nil
function animation:remove()
end

---An animation frame handler. It is called every frame before drawing stuff to the screen buffer.
---@param animation table A pointer to the animation object
---@return nil
function animation.frameHandler(animation)
end

---This function is called after finishing animation playback.
---@return nil
function animation.onFinish()
end

-------------------------------------------------------------------------------------------------------------------------

---@class GUI.text : GUI.object
local text = {}

---Creates a new text object.
---@param x number Object coordinate by x-axis
---@param y number Object coordinate by y-axis
---@param textColor number Object text color
---@param text string Object text
---@return GUI.text
function GUI.text(x, y, textColor, text)
end

-------------------------------------------------------------------------------------------------------------------------

---@class GUI.label : GUI.object
local label = {}

---Creates a new label object.
---@param x number Object coordinate by x-axis
---@param y number Object coordinate by y-axis
---@param width number Object width
---@param height number Object height
---@param textColor number Object text color
---@param text string Object text
---@return GUI.label
function GUI.label(x, y, width, height, textColor, text)
end

---Choose a text display option for label boundaries.
---@param horizontalAlignment Horizontal_alignment Horizontal alignment option
---@param verticalAlignment Vertical_alignment Vertical alignment option
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

---@class GUI.button : GUI.object
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
---@return nil
function button:onTouch()
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

---@class GUI.input : GUI.object
local input = {}

---Creates a new input object.
---@param x number Object coordinate by x-axis
---@param y number Object coordinate by y-axis
---@param width number Object width
---@param height number Object height
---@param backgroundColor number Object default background color
---@param textColor number Object default text color
---@param placeholderTextColor number Object placeholder color
---@param backgroundFocusedColor number Object focused background color
---@param textFocusedColor number Object focused text color
---@param text string Object text value
---@param placeholderText string Text to be displayed, provided that the entered text is empty
---@param eraseTextOnFocus boolean Erase text when the input is focused
---@param textMask string A mask character for the text to be entered. Convenient for creating a password entry field
---@return GUI.input
function GUI.input(x, y, width, height, backgroundColor, textColor, placeholderTextColor, backgroundFocusedColor,textFocusedColor, text, placeholderText, eraseTextOnFocus, textMask)
end

---A variable that contains current displayed text of an object.
---@type string
input.text = ""

---Optional property that allows widget to remember text that user inputs and to navigate through its history via arrows buttons. Set to false by default.
---@type boolean
input.historyEnabled = false

---Method for activation of text inputting.
---@return nil
function input:startInput()
end

---The function that is called after the text is entered in the input field. If it returns true, the text in the text field will be changed to the entered text, otherwise the entered data will be ignored.
---@param text string The entered text
---@return boolean Whether the text is valid
function input.validator(text)
end

---The function that is called after entering data in the input field: it's a handy thing if you want to do something after entering text. If the object has .validator function, and if the text does not pass the check through it, then .onInputFinished will not be called.
---@return nil
function input.onInputFinished()
end

-------------------------------------------------------------------------------------------------------------------------

---@class GUI.slider : GUI.object
local slider = {}

---Creates a new slider object.
---@param x number Object coordinate by x-axis
---@param y number Object coordinate by y-axis
---@param width number Object width
---@param primaryColor number Object primary color
---@param secondaryColor number Object secondary color
---@param pipeColor number Object "pipe" color
---@param valueColor number Object text value color
---@param minimumValue number Object minimum value
---@param maximumValue number Object maximum value
---@param value number Object current value
---@param showCornerValues? boolean Do min/max values are needed to be shown at slider's corners
---@param currentValuePrefix? string Prefix for value displaying
---@param currentValuePostfix? string Postfix for value displaying
---@return GUI.slider
function GUI.slider(x, y, width, primaryColor, secondaryColor, pipeColor, valueColor, minimumValue, maximumValue, value, showCornerValues, currentValuePrefix, currentValuePostfix)
end

---Current slider value variable.
---@type number
slider.value = 0.0

---This property will visually round slider values.
---@type boolean
slider.roundValues = false

---This function will be called after slider value changing.
---@return nil
function slider.onValueChanged()
end

---Determines how big part of content must be scrolled using mouse wheel. Note that property works as percentage, not pixels. The default value is 0.05.
---@type number
slider.scrollSensitivity = 0.05

---This function will be called after value changing by mouse wheel.
---@return nil
function slider.onScroll()
end

-------------------------------------------------------------------------------------------------------------------------

---@class GUI.switch : GUI.object
local switch = {}

---Creates a new switch object.
---@param x number Object coordinate by x-axis
---@param y number Object coordinate by y-axis
---@param width number Object width
---@param primaryColor number Object primary color
---@param secondaryColor number Object secondary color
---@param pipeColor number Object "pipe" color
---@param state boolean Object state
---@return GUI.switch
function GUI.switch(x, y, width, primaryColor, secondaryColor, pipeColor, state)
end

---Current switch state variable.
---@type boolean
switch.state = false

---Change switch state to specified one.
---@param state boolean The desired state of the switch
---@return nil
function switch:setState(state)
end

---This function will be called when switch state is changed.
---@return nil
function switch.onStateChanged()
end

-------------------------------------------------------------------------------------------------------------------------

---@class GUI.switchAndLabel : GUI.container
switchAndLabel = {}

---Creates a new switch and label container.
---@param x number Object coordinate by x-axis
---@param y number Object coordinate by y-axis
---@param width number Total width
---@param switchWidth number Switch width
---@param primaryColor number Switch primary color
---@param secondaryColor number Switch secondary color
---@param pipeColor number Switch "pipe" color
---@param textColor number Label text color
---@param text string Label text
---@param switchState boolean Switch state
---@return GUI.switchAndLabel
function GUI.switchAndLabel(x, y, width, switchWidth, primaryColor, secondaryColor, pipeColor, textColor, text, switchState)
end

---Pointer to switch child object.
---@type table
switchAndLabel.switch = {}

---Pointer to label child object.
---@type table
switchAndLabel.label = {}
