$ ->
	charSource =  $('#char-stats').html()
	dashSource = $('#dash-board').html()
	pathSource = $('#path-chosen').html()

	handleChar = Handlebars.compile(charSource)
	handleDash = Handlebars.compile(dashSource)
	handlePath = Handlebars.compile(pathSource)



	$dash = $('#dashBoard')
	$completed = $('#completedQuests')
	$current = $('#currentQuests')
	$charStats = $('#charStats')
	$game = $('#gameAch')
	$current = $('#currentQuests')
	$path = $('#currentPath')

	updateDashboard = (char) ->
		$dash.html handleDash char
		$charStats.html handleChar char
		$path.html handlePath char

	$.get '/charData', {}, (userCharacter) ->
		console.log userCharacter
		updateDashboard(userCharacter)


	$(document).on 'click', '.choosePath', () ->
		$('#pathChooser').fadeOut()
		$.get '/charData', {}, (userCharacter) ->
			updateDashboard(userCharacter)

	$(document).on 'click', '.addQuest', () ->
		$('.currentQuestList').append($('<p class="quest">Embark on a new quest!</p>'))
		$('.quest').hallo({editable : true})

	$(document).on 'click', '.addDaily', () ->
		$('.dailyQuestList').append($('<p class="daily">Enter new Daily</p>'))
		$('.daily').hallo({editable : true})


	$(document).on 'hallodeactivated', '.quest', () ->
		$(@).fadeOut('fast').fadeIn('fast')
		quest = $(@).text()
		$.post '/addQuest', {currentQuest : quest}, (data) ->

	$(document).on 'hallodeactivated', '.daily', () ->
		$(@).fadeOut('fast').fadeIn('fast')
		daily = $(@).text()
		$.post '/addDaily', {daily : daily}, (data) ->
	return