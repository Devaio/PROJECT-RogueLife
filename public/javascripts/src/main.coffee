$ ->



	$('.signUp').on 'submit', (e) ->
		e.preventDefault()
		serialData = $(@).serialize()
		$.post "/signup", serialData, (data) ->
			if data.message
				$('.error').fadeIn 'fast', () ->
					$('.error').fadeOut 'slow'
			else
				$.post '/signin', serialData, (data) ->
					console.log serialData
					console.log data
					window.location = data.redirect
				$('#signUpModal').modal 'toggle'
		return

	$('.signIn').on 'submit', (e) ->
		e.preventDefault()
		serialData = $(@).serialize()
		console.log 'outsidepost', serialData
		$.post '/signin', serialData, (data) ->
			console.log 'insidepost', serialData
			window.location = data.redirect
		.fail () ->
			$('#error').fadeIn 'slow', () ->
				$('#error').fadeOut 'slow'


	$(document).on 'click', '.choosePath', () ->
		chosenPath = $(@).attr('data-path')
		$.post '/chosenpath', {path : chosenPath}, (data) ->
			console.log chosenPath






	
	return