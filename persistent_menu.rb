class PersistentMenu
  def self.enable
    # Create persistent menu
    Facebook::Messenger::Thread.set({
      setting_type: 'call_to_actions',
      thread_state: 'existing_thread',
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
    }, access_token: ENV['ACCESS_TOKEN'])
  end
end
