$ ->



	$('.signUp').on 'submit', (e) ->
		e.preventDefault()
		serialData = $(@).serialize()
		$.post "/signup", serialData, (data) ->
			console.log data
		$('#signUpModal').modal 'toggle'
		return

	$('.signIn').on 'submit', (e) ->
		e.preventDefault()
		serialData = $(@).serialize()
		console.log 'outsidepost', serialData
		$.post '/signin', serialData, (data) ->
			console.log 'insidepost', serialData
			window.location = data.redirect


	$(document).on 'click', '.choosePath', () ->
		chosenPath = $(@).attr('data-path')
		$.post '/chosenpath', {path : chosenPath}, (data) ->
			console.log chosenPath






	
	return