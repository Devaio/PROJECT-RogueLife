$ ->
	socket = io.connect()
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
	$('.questName').hallo({editable : true})
	$('.dailyName').hallo({editable : true})

	updateDashboard = (char) ->
		$dash.html handleDash char
		$charStats.html handleChar char
		$path.html handlePath char

	$.get '/charData', {}, (userCharacter) ->
		console.log userCharacter
		updateDashboard(userCharacter)
		$('.questName').hallo({editable : true})
		$('.dailyName').hallo({editable : true})
		


	$(document).on 'click', '.choosePath', () ->
		$('#pathChooser').fadeOut()
		$.get '/charData', {}, (userCharacter) ->
			updateDashboard(userCharacter)

	$(document).on 'click', '.addQuest', () ->
		$('.currentQuestList').append($('<li class="quest list-unstyled"><span class="questName">Enter a new Quest</span><div class="taskStatus"></div><div class="questTimer pull-right text-muted">'+moment().format('lll')+'</div></li>'))
		$('.questName').hallo({editable : true})
		

	$(document).on 'click', '.addDaily', () ->
		$('.dailyQuestList').append($('<li class="daily list-unstyled"><span class="dailyName">Enter a new Daily</span><div class="taskStatus"></div></li>'))
		$('.dailyName').hallo({editable : true})

	$(document).on 'halloactivated', '.questName', () ->
		quest = $(@).text()
		$.post '/removeQuest', {questName : quest}, () ->
	
	$(document).on 'hallodeactivated', '.questName', () ->
		$(@).fadeOut('fast').fadeIn('fast')
		quest = $(@).text()
		$.post '/updateQuest', {questName : quest}, () ->

	$(document).on 'halloactivated', '.dailyName', () ->
		daily = $(@).text()
		$.post '/removedaily', {dailyName : daily}, () ->

	$(document).on 'hallodeactivated', '.dailyName', () ->
		$(@).fadeOut('fast').fadeIn('fast')
		daily = $(@).text()
		$.post '/updateDaily', {dailyName : daily}, () ->
		
	
	socket.on 'connected', (data) ->
		console.log 'connected'





	return




