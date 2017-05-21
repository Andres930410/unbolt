require 'facebook/messenger'
require 'httparty'
require 'json'
include Facebook::Messenger
require_relative 'persistent_menu'

# Subcribe bot to your page
Facebook::Messenger::Subscriptions.subscribe(access_token: ENV["ACCESS_TOKEN"])

UNBOT = "https://westus.api.cognitive.microsoft.com/luis/v2.0/apps/ae7007ff-6b7d-4f73-be7a-cb26e2802087?subscription-key=21cc724246db40e0bbf9dd0fd9817432&timezoneOffset=0&verbose=true&q="
IDIOMS = {
  general: ["Cuantos años tiene el cyt","historia del viejo","cuando fue fundado enfermeria","apodo del 401","numero del liq", "quien es julio zorra"],
  position: ["Donde que el viejo","ubicacion de enfermeria","coordenadas de aulas","por donde es el polideportivo","por que lado es el 401"],
  route: ["camino del leon a enfermeria","ruta del liq a facultad de ingenieria","caminar de enfermeria a aulas","lleveme de aulas al cyt"]
}

NONE = ["Lo siento pero no te entendi","el problema es realmente duro, intentalo formular de otra manera","no se","me corchaste"]
GREETINGS = {
  greet: ["hola", "hi", "hello","hey"],
  about: ["bien, como vas", "bien, como has estado", "bien, que tal la u","bien, que tal la vida","bien, como van las cosas"],
  about_doing: ["esperando para resolverte cualquier duda o problema que tengas \n que haces","he estado esperando, pero ahora estoy feliz porque ya pude conocerte, \n que has hecho","tengo planeado ponerme a tu disposicion para solucionar cualquier duda que tengas \n que tienes planeado"]
}

MENU_REPLIES = [
  {
    content_type: 'text',
    title: 'Informacion',
    payload: 'INFORMATION'
  },
  {
    content_type: 'text',
    title: 'Rutas',
    payload: 'ROUTE'
  },
  {
    content_type: 'text',
    title: 'Localizacion',
    payload: 'LOCATION'
  }
].freeze

Bot.on :postback do |postback|
  sender_id = postback.sender['id']
  case postback.payload
  when 'INFORMATION'
    example_information(sender_id)
    way_for_any_input
  when 'ROUTE'
    example_route(sender_id)
    way_for_any_input
  when 'LOCATION'
    example_location(sender_id)
    way_for_any_input
  end
end

def example_information(id)
  say(id,"Porque no preguntas: "+ IDIOMS[:general].sample)
end

def example_location(id)
  say(id,"Porque no preguntas: "+ IDIOMS[:position].sample)
end

def example_route(id)
  say(id,"Porque no preguntas: "+ IDIOMS[:route].sample)
end

def say(id,text,menu = nil)
  message_options = {
  recipient: { id: id },
  message: { text: text }
  }
  if menu
    message_options[:message][:quick_replies] = menu
  end
  Bot.deliver(message_options, access_token: ENV['ACCESS_TOKEN'])
end

def way_for_any_input
  Bot.on :message do |message|
    if message.text == "Informacion"
       message.reply(text: "Como por ejemplo: "+ IDIOMS[:general].sample)
    elsif message.text == "Rutas"
      message.reply(text: "Podrias preguntar: " + IDIOMS[:route].sample)
    elsif message.text == "Localizacion"
      message.reply(text: "Yo puedo responder: " + IDIOMS[:position].sample)
    else
      result = unbot(message.text)
      p result
      p result["topScoringIntent"]["intent"]
      case result["topScoringIntent"]["intent"]
      when "Greeting"
        show_replies_menu(message.sender['id'],MENU_REPLIES,result["entities"])
      when "LocateBuilding"
        handle_location_building(message,result[:entities])
      when "Route"
        handle_route(message,result[:entities])
      when "ShowInformation"
        handle_information(message,result[:entities])
      else
        show_replies_menu_none
      end
    end
  end
end

def show_replies_menu_none(id)
  text = NONE.sample
  say(id,text)
  way_for_any_input
end

def show_replies_menu(id,menu,entities)

  if entities != nil && !entities.empty?
    text = ""
    entities.each do |a|
      if a["type"] != "without_answer"
        x = a["type"]
        text = text + GREETINGS[x.to_sym].sample + ""
      else
        text = text + "ok"
      end
    end
  else
    text = "ok"
  end
  say(id,text,menu)
  way_for_any_input
end

def handle_location_building(message,entities)
  way_for_any_input
end

def handle_route(message,entities)
  way_for_any_input
end

def handle_information(message,entities)
  way_for_any_input
end

def unbot(message)
  response = HTTParty.get(UNBOT+message)
  parsed = JSON.parse(response.body)

end

way_for_any_input
