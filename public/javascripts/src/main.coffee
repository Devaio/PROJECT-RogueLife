$ ->
	# dataSource = $('#completed-tasks').html();
	# searchTemplate = Handlebars.compile(dataSource)
	# $completed = $('#completedList')





	$('.signUp').on 'submit', (e) ->
		e.preventDefault()
		serialData = $(@).serialize()
		$.post "/signup", serialData, (data) ->
			console.log data
			return
		$('#signUpModal').modal 'toggle'
		return

	$('.signIn').on 'submit', (e) ->
		e.preventDefault()
		serialData = $(@).serialize()
		console.log 'in', serialData
		$.post '/signin', serialData, (data) ->
			console.log 'out', serialData
			window.location = data.redirect
			return
		return








	
	return