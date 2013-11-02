$ ->
	charSource =  $('#char-stats').html()
	dashSource = $('#dash-board').html()

	updateChar = Handlebars.compile(charSource)
	updateDash = Handlebars.compile(dashSource)



	$dash = $('#dashBoard')
	$completed = $('#completedQuests')
	$current = $('#currentQuests')
	$charStats = $('#charStats')
	$game = $('#gameAch')
	$current = $('#currentQuests')


	$.get '/charData', {}, (userCharacter) ->
		console.log userCharacter
		$dash.html updateDash userCharacter
		$charStats.html updateChar userCharacter


	$(document).on 'click', '.choosePath', () ->
		$('#pathChooser').fadeOut()
		$.get '/charData', {}, (userCharacter) ->
			$dash.html updateDash userCharacter
			$charStats.html updateChar userCharacter

	$(document).on 'click', '.addQuest', () ->
		$('#currentQuests').append($('<p class="quest">QuestTest</p>'))
		$('.quest').hallo({editable : true})


	$(document).on 'hallodeactivated', '.quest', () ->
		$(@).fadeOut('fast').fadeIn('fast')
		quest = $(@).text()
		console.log quest
		$.post '/addQuest', {currentQuest : quest}, (data) ->
			console.log 'datafromhallodeactive', data
	return