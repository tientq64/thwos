task.import "npm:md5js"

class ChangePassword extends React.Component
	constructor: (props) ->
		super props
		@$autoBind()

		@fields =
			oldPassword:
				label: "Mật khẩu cũ"
				value: ""
				errText: ""
				el: null
			newPassword:
				label: "Mật khẩu mới"
				value: ""
				errText: ""
				el: null
			repeatNewPassword:
				label: "Nhập lại mật khẩu mới"
				value: ""
				errText: ""
				el: null

	onSubmit: (event) ->
		event.preventDefault()
		oldPassword = md5.md5 @fields.oldPassword.value, 32
		newPassword = @fields.newPassword.value
		repeatNewPassword = @fields.repeatNewPassword.value
		if oldPassword is ap.user.password
			newPassword = ap.validatePassword newPassword
			if _.isError newPassword
				@fields.newPassword.errText = newPassword.message
				@fields.newPassword.el.focus()
			else
				if newPassword is repeatNewPassword
					ap.user.password = md5.md5 newPassword, 32
					task.close yes
				else
					@fields.repeatNewPassword.errText = "Mật khẩu nhập lại không khớp"
					@fields.repeatNewPassword.el.focus()
		else
			@fields.oldPassword.errText = "Mật khẩu cũ không đúng"
			@fields.oldPassword.el.focus()
		@setState {}
		return

	handleChange: (field, event) ->
		field.value = event.target.value
		for k, field of @fields
			field.errText = ""
		@setState {}
		return

	render: ->
		<form className="p-3" onSubmit={@onSubmit}>
			{_.map @fields, (field, k) =>
				<FormGroup
					label={field.label}
					intent="danger"
					helperText={field.errText}
				>
					<InputGroup
						autoFocus={k is "oldPassword"}
						type="password"
						intent={"danger" if field.errText}
						value={field.value}
						inputRef={(el) => @fields[k].el = el}
						onChange={(event) => @handleChange field, event}
					/>
				</FormGroup>
			}
			<div className="text-right">
				<Button type="submit" text="OK"/>
			</div>
		</form>
