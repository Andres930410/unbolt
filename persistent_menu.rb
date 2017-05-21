include Facebook::Messenger

class PersistentMenu
  def self.enable
    # Create persistent menu
    Facebook::Messenger::Profile.set({
    persistent_menu: [
      locale: 'default',
      composer_input_disabled: true,
      call_to_actions: [
        {
          type: 'postback',
          title: 'Informacion',
          payload: 'INFORMATION'
        },
        {
          type: 'postback',
          title: 'Rutas',
          payload: 'ROUTE'
        },
        {
          type: 'postback',
          title: 'Localizacion',
          payload: 'LOCATION'
        }
      ]
    ]
    }, access_token: ENV['ACCESS_TOKEN'])
  end
end
