class TaskbarHome extends React.Component
	constructor: (props) ->
		super props
		@$autoBind()

		@applsQuery = ""
		@applsItems = []
		@applsIndex = 0
		@applsEl = null

	updateAppls: ->
		@updateApplsItems()
		return

	resetAppls: ->
		@applsQuery = ""
		@applsItems = []
		@setState {}
		return

	handleClickApplsItem: (item) ->
		app.runTask item.obj.path + "/app.yml"
		@resetAppls()
		return

	updateApplsItems: ->
		@applsIndex = 0
		if @applsQuery
			@applsItems = fuzzysort.go @applsQuery, Object.values(app.appls), key: "name"
		else
			@applsItems = _.map app.appls, (appl) =>
				indexes: [-1]
				obj: appl
				score: 0
				target: appl.name
		@setState {}
		return

	onChangeAppls: (event) ->
		@applsQuery = event.target.value
		@updateApplsItems()
		@setState {}
		return

	onKeyDownAppls: (event) ->
		switch event.key
			when "ArrowDown", "ArrowUp"
				event.preventDefault()
				if @applsItems.length
					@applsIndex = (@applsIndex + (event.key is "ArrowDown" and 1 or -1)) %% @applsItems.length
					@setState {}, =>
						@applsEl.children[@applsIndex].scrollIntoView
							behavior: "smooth"
							block: "nearest"
						return
			when "Enter"
				if @applsItems.length
					document.querySelectorAll(".TaskbarHome__applsItem")[@applsIndex].click()
		return

	componentDidMount: ->
		@updateApplsItems()
		return

	render: ->
		<Popover
			minimal
			position="top"
			onOpening={=> @updateAppls()}
			onClosed={=> @resetAppls()}
			content={
				<div className="column p-3" style={width: 260, maxHeight: "50vh"}>
					<div className="row mb-3 middle">
						<div className="col-0">
							<img
								className="img-cover rounded block"
								src={ap.user.avatar}
								width={64}
								height={64}
							/>
						</div>
						<div className="col pl-3 w-0">
							<H4 className="text-ellipsis">{ap.user.name}</H4>
						</div>
					</div>
					{if @applsItems.length
						<Menu className="col scroll p-0 mb-3" ulRef={(@applsEl) =>}>
							{@applsItems.map (item, i) =>
								<MenuItem
									key={i}
									className="TaskbarHome__applsItem"
									active={@applsIndex is i}
									icon={item.obj.icon}
									text={
										<span dangerouslySetInnerHTML={__html: fuzzysort.highlight item, "<b>", "</b>"}/>
									}
									onClick={=> @handleClickApplsItem item}
								/>
							}
						</Menu>
					}
					<InputGroup
						autoFocus
						value={@applsQuery}
						onChange={@onChangeAppls}
						onKeyDown={@onKeyDownAppls}
					/>
				</div>
			}
		>
			<Button id="TaskbarHome__btn" minimal icon="key-command"/>
		</Popover>
