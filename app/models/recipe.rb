require 'open-uri'

class Recipe < ApplicationRecord
  after_save if: -> { saved_change_to_name? || saved_change_to_ingredients? } do
    set_content
    set_photo
  end


  has_one_attached :photo
  # def content
  #   Rails.cache.fetch("#{cache_key_with_version}/content") do #value will recalculate even when cached if the underlying data has changed
  #     client = OpenAI::Client.new
  #     chaptgpt_response = client.chat(parameters: {
  #       model: "gpt-3.5-turbo",
  #       messages: [{ role: "user", content: "Give me a simple recipe for #{name} with the ingredients #{ingredients}. Give me only the text of the recipe, without any of your own answer like 'Here is a simple recipe'."}]
  #     })
  #     chaptgpt_response["choices"][0]["message"]["content"]
  #   end
  # end

  def content #only load response from chatGPT if the content is blank
    if super.blank? #if the content method normally gives you nothing
      set_content
    else
      super
    end
  end

  private

  def set_content
    client = OpenAI::Client.new
    chaptgpt_response = client.chat(parameters: {
      model: "gpt-3.5-turbo",
      messages: [{ role: "user", content: "Give me a simple recipe for #{name} with the ingredients #{ingredients}. Give me only the text of the recipe, without any of your own answer like 'Here is a simple recipe'."}]
    })
    new_content = chaptgpt_response["choices"][0]["message"]["content"]
    update(content: new_content) # same as self.update
    new_content
  end

  def set_photo
    client = OpenAI::Client.new
    response = client.images.generate(parameters: {
      prompt: "Give me an image of #{name}",
      size: "256x256"
    })
    url = response["data"][0]["url"]
    file = URI.open(url)
    photo.purge if photo.attached?
    photo.attach(io: file, filename: "#{name}.png", content_type: "image/png" )
    photo
  end
end
