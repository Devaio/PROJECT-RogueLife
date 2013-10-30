$ ->
	$('.signUp').on 'submit', (e) ->
		e.preventDefault()
		console.log $(@).serialize()
		$.post "/signup", $(@).serialize(), (data) ->
			console.log data
			return
		$('#signUpModal').modal 'toggle'
		return









	
	return