$ ->
	dataSource = $('#completed-tasks').html();
	searchTemplate = Handlebars.compile(dataSource)
	$completed = $('#.completedList')





	$('.signUp').on 'submit', (e) ->
		e.preventDefault()
		$.post "/signup", $(@).serialize(), (data) ->
			return
		$('#signUpModal').modal 'toggle'
		return

	$('.signIn').on 'submit', (e) ->
		e.preventDefault()
		$.post '/signin', $(@).serialize(), (data) ->
			console.log data
			$('input').val('')
			return
		.fail(console.log 'Failed')
		return








	
	return