extends Node

signal request_completed(response_code, body)
@onready var http: HTTPRequest = $HTTPRequest

func _ready():
	http.request_completed.connect(_on_request_completed)

func submit_email_form(email: String) -> bool:
	var url = "https://formspree.io/f/xeokbyyb"
	var headers = ["Content-Type: application/json"]
	var body = {
		"email": email
	}

	var json_body = JSON.stringify(body)
	var error = http.request(url, headers, HTTPClient.METHOD_POST, json_body)

	if error != OK or email.is_empty():
		print("Request failed: ", error)
		return false
	else:
		return true

func _on_request_completed(result, response_code, headers, body):
	print("Form response code: ", response_code)
	print("Body: ", body.get_string_from_utf8())
	if response_code == 200 or response_code == 202:
		print("Email submitted successfully!")
	else:
		print("Submission failed.")
		
	emit_signal("request_completed", response_code, body)
