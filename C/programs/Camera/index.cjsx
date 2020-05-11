class App extends React.Component
	constructor: (props) ->
		super props
		@$autoBind()

		@g = null
		@img = null

	$listen: (name, val) ->
		switch name
			when "$media"
				@img.src = val
		return

	componentDidMount: ->
		data = await task.initMedia
			video: yes
			audio: no
		if _.isError data
		else
			@refs.canvas.width = data.width
			@refs.canvas.height = data.height
			@g = @refs.canvas.getContext "2d"
			@img = new Image
			@img.onload = =>
				@g.clearRect 0, 0, @refs.canvas.width, @refs.canvas.height
				@g.drawImage @img, 0, 0
				return
			task.setSizeWinFitContent()
		return

	render: ->
		<div className="p-3">
			<canvas ref="canvas"/>
		</div>
