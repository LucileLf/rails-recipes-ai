class Recipe < ApplicationRecord
  after_save :set_content, if: -> { saved_change_to_name? || saved_change_to_ingredients? }
  
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
end
