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
	$('.questName').hallo({editable : true})
	$('.dailyName').hallo({editable : true})

	updateDashboard = (char) ->
		$dash.html handleDash char
		$charStats.html handleChar char
		$path.html handlePath char

	$.get '/charData', {}, (userCharacter) ->
		console.log userCharacter
		updateDashboard(userCharacter)
		$('.quest').hallo({editable : true})
		$('.daily').hallo({editable : true})
		console.log 'time', userCharacter.currentQuests[0].startQuest.fromNow()


	$(document).on 'click', '.choosePath', () ->
		$('#pathChooser').fadeOut()
		$.get '/charData', {}, (userCharacter) ->
			updateDashboard(userCharacter)

	$(document).on 'click', '.addQuest', () ->
		$('.currentQuestList').append($('<li class="quest list-unstyled"><span class="questName">Enter a new Quest</span><div class="taskStatus"></div><span class="questTimer pull-right text-muted">'+moment()+'</span></li>'))
		$('.questName').hallo({editable : true})

	$(document).on 'click', '.addDaily', () ->
		$('.dailyQuestList').append($('<p class="daily">Enter new Daily</p>'))
		$('.dailyName').hallo({editable : true})


	$(document).on 'hallodeactivated', '.questName', () ->
		$(@).fadeOut('fast').fadeIn('fast')
		quest = $(@).text()
		timeStamp = moment().format('L')
		$.post '/addQuest', {currentQuest : quest, time : timeStamp}, (data) ->

	$(document).on 'hallodeactivated', '.dailyName', () ->
		$(@).fadeOut('fast').fadeIn('fast')
		daily = $(@).text()
		$.post '/addDaily', {daily : daily}, (data) ->
	






	return




