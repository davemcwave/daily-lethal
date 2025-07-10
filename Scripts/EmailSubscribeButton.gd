extends Button

@onready var email_text_input: LineEdit = get_parent().get_node("EmailTextInput")
@onready var subscribe_help_text: RichTextLabel = get_parent().get_node("SubscribeHelpText")
@onready var email_handler = $"/root/EmailHandler"
@onready var overlay = get_parent()


func _ready() -> void:
	if has_subscribe_prompt_been_shown():
		overlay.queue_free()
	else:
		mark_subscribe_prompt_shown()
		email_handler.connect("request_completed", self.on_email_handler_request_completed)
		email_text_input.grab_focus()

func has_subscribe_prompt_been_shown() -> bool:
	var result = JavaScriptBridge.eval("localStorage.getItem('subscribePromptShown')", true)
	return result == "true"

func mark_subscribe_prompt_shown():
	JavaScriptBridge.eval("localStorage.setItem('subscribePromptShown', 'true');")

func on_email_handler_request_completed(response_code, response_body) -> void:
	if response_code == 200:
		await show_subscribe_help_text("Thanks for subscribing! Puzzles incoming.")
		overlay.queue_free()
	else:
		await show_subscribe_help_text("Form submit unsuccessful.")

func show_subscribe_help_text(text: String, duration: float = 2.0) -> bool:
	subscribe_help_text.set_text("[center][b]%s[/b][/center]" % text)
	subscribe_help_text.show()
	await get_tree().create_timer(duration).timeout
	subscribe_help_text.hide()
	return true
	
func _on_pressed() -> void:
	var success: bool = email_handler.submit_email_form(email_text_input.get_text())
	if not success:
		await show_subscribe_help_text("Form submit unsuccessful.")


func _on_email_text_input_text_submitted(new_text: String) -> void:
	_on_pressed()
