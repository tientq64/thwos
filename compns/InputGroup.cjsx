class InputGroup extends React.Component
	constructor: (props) ->
		super props
		@$autoBind()

		@isOpenEmoji = no
		@inputEl = null
		@popperUpdateEmoji = null
		@emojis = null

	rangeEmojis: (list) ->
		list
			.map (item) =>
				item[1].map (range) =>
					_.range(range[0], range[1] + 1).map (i) => String.fromCharCode item[0], i
			.flat 2

	initEmojis: ->
		@emojis ?= @rangeEmojis [
			[55356, [
				[56324, 56324]
				[56527, 56527]
				[56688, 56689]
				[56702, 56703]
				[56718, 56718]
				[56721, 56730]
				[56833, 56833]
				[56858, 56858]
				[56879, 56879]
				[56882, 56886]
				[56888, 56890]
				[56912, 56913]
				[57088, 57120]
				[57133, 57141]
				[57143, 57212]
				[57214, 57235]
				[57248, 57292]
				[57295, 57299]
				[57312, 57328]
				[57332, 57332]
				[57336, 57338]
			]]
			[55357, [
				[56320, 56382]
				[56384, 56384]
				[56386, 56572]
				[56575, 56637]
				[56651, 56654]
				[56656, 56679]
				[56692, 56693]
				[56698, 56698]
				[56720, 56720]
				[56725, 56726]
				[56740, 56740]
				[56827, 56911]
				[56960, 57029]
				[57036, 57036]
				[57040, 57042]
				[57045, 57045]
				[57067, 57068]
				[57076, 57082]
				[57312, 57323]
			]]
			[55358, [
				[56589, 56634]
				[56636, 56645]
				[56647, 56689]
				[56691, 56694]
				[56698, 56738]
				[56741, 56746]
				[56750, 56778]
				[56781, 56831]
				[56944, 56947]
				[56952, 56954]
				[56960, 56962]
				[56976, 56981]
			]]
		]
		return

	inputRef: (@inputEl) =>
		@props.inputRef? @inputEl
		return

	handleClickEmojiItem: (emoji) ->
		if @inputEl
			(({selectionStart, selectionEnd}) =>
				@inputEl.value = @props.value[...selectionStart] + emoji + @props.value[selectionEnd..]
				inputEvent =
					type: "change"
					currentTarget: @inputEl
					target: @inputEl
				@onChange? inputEvent
				@setState {}, =>
					@inputEl.selectionStart = @inputEl.selectionEnd = selectionStart + emoji.length
					@inputEl.blur()
					@inputEl.focus()
					return
				return
			) @inputEl
		return

	onFocus: (event) ->
		@props.onFocus? event
		if @props.selectAllOnFocus
			if @inputEl
				@inputEl.selectionEnd = @inputEl.selectionStart
				@inputEl.select()
		return

	onContextMenu: (event) ->
		@props.onContextMenu? event
		ap.showContextMenu [
			text: "Biểu tượng cảm xúc"
			icon: "far:laugh"
			onClick: =>
				@isOpenEmoji = yes
				@initEmojis()
				@inputEl?.focus()
				@setState {}
				return
		]
		return

	onChange: (event) ->
		@props.onChange? event
		@setState {}, =>
			@popperUpdateEmoji?()
			return
		return

	rightElement: ->
		[
			...(_.castArray @props.rightElement)
			if @emojis
				<Popover
					className="InputGroup__emojiTarget"
					minimal
					position="top-right"
					inheritDarkTheme={no}
					popperUpdateRef={(@popperUpdateEmoji) =>}
					modifiers={
						offset: offset: "5px, 5px"
					}
					isOpen={@isOpenEmoji}
					onInteraction={(@isOpenEmoji) => @setState {}}
					content={
						<div className="p-2 InputGroup__emoji">
							<div className="row middle">
								<div className="col pl-2">Biểu tượng cảm xúc</div>
								<Button
									small
									minimal
									intent="danger"
									icon="cross"
									onClick={=>
										@isOpenEmoji = no
										@setState {}, =>
											@inputEl.focus()
											return
										return
									}
								/>
							</div>
							<div className="my-2 text-center InputGroup__emojiList">
								{@emojis.map (emoji) =>
									<div
										className="InputGroup__emojiItem"
										onMouseDown={=>
											setTimeout =>
												@inputEl.focus()
												return
											return
										}
										onClick={=>
											@handleClickEmojiItem emoji
											return
										}
									>
										{emoji}
									</div>
								}
							</div>
						</div>
					}
				>
					<span/>
				</Popover>
		]

	render: ->
		<Blueprint.Core.InputGroup
			{...@props}
			inputRef={@inputRef}
			rightElement={@rightElement()}
			value={@props.value}
			onFocus={@onFocus}
			onContextMenu={@onContextMenu}
			onChange={@onChange}
		/>
