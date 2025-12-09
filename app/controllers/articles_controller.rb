class ArticlesController < ApplicationController
  def index
    matching_articles = Article.all

    @list_of_articles = matching_articles.order({ :created_at => :desc })

    render({ :template => "article_templates/index" })
  end

  def show
    the_id = params.fetch("path_id")

    matching_articles = Article.where({ :id => the_id })
    matching_sections = Section.where({ :article_id => the_id }).order(:placement)

    @the_article = matching_articles.at(0)
    @list_of_sections = matching_sections

    render({ :template => "article_templates/show" })
  end

  def generate
    topic_id = params.fetch("query_topic_id")
    user_description = params.fetch("query_user_description")

    topic_generation_system_prompt = "You are a tool for generating articles on different topics for students using the notes they have acquired. You will read user descriptions of the article they want to write along with notes they have about the topic. You should format their idea into a title, short summary, and proposed section outline taking into account the information included in the notes. The title should use the language of the user description of their idea and be short and straightforward. There should be no more than 5 sections and each one should have a title that makes it clear what the section is about. The summary should cover the same sections described but in a sentence format."
    topic_generation_schema = <<~JSON
    {
      "$schema": "http://json-schema.org/draft-07/schema#",
      "title": "RootObject",
      "type": "object",
      "properties": {
        "title": {
          "type": "string",
          "description": "A short title for the article."
        },
        "summary": {
          "type": "string",
          "description": "A longer description or summary."
        },
        "sections": {
          "type": "array",
          "description": "A list of article sections.",
          "items": {
            "type": "object",
            "properties": {
              "title": {
                "type": "string",
                "description": "Section title."
              },
              "order": {
                "type": "integer",
                "description": "Sorting order of the section."
              }
            },
            "required": ["title", "order"],
            "additionalProperties": false
          }
        }
      },
      "required": ["title", "summary", "sections"],
      "additionalProperties": false
    }
    JSON

    notes_with_files = Note.where({ :topic_id => topic_id }).with_attached_file.where.associated(:file_attachment)
    note_file_urls = notes_with_files.map do |note|
      local_file_path = ActiveStorage::Blob.service.path_for(note.file.key)
      # TODO: Support upload of non-local storage
      # rails_blob_url(note.file, only_path: true)
      local_file_path
    end
    notes_with_content = Note.where({ :topic_id => topic_id }).where.not(content: [ nil, "" ])
    note_content_string = ""
    notes_with_content.each_with_index do |note, idx|
      note_name = note.name.present? ? note.name : idx
      note_content_string << "#{note_name}\n" << note.content << "\n"
    end

    user_prompt = "User Idea:\n#{user_description}\n\n User Notes:\n#{note_content_string}"

    c = AI::Chat.new
    c.system(topic_generation_system_prompt)
    c.user(user_prompt, files: note_file_urls)
    c.schema = topic_generation_schema

    ai_response = c.generate!
    data = ai_response[:content]

    the_article = Article.new
    the_article.topic_id = topic_id
    the_article.title = data[:title]
    the_article.summary = data[:summary]

    if the_article.valid?
      the_article.save

      data[:sections].each do |section|
        the_section = Section.new
        the_section.name = section[:title]
        the_section.article_id = the_article.id
        the_section.placement = section[:order]
        the_section.text_content = ""

        if the_section.valid?
          the_section.save
        end
      end

      redirect_to("/articles/#{the_article.id}", { :notice => "Article created successfully." })
    else
      redirect_to("/topics/#{topic_id}", { :alert => the_article.errors.full_messages.to_sentence })
    end
  end

  def create
    the_article = Article.new
    the_article.topic_id = params.fetch("query_topic_id")
    the_article.title = params.fetch("query_title")
    the_article.summary = params.fetch("query_summary")

    if the_article.valid?
      the_article.save
      redirect_to("/articles", { :notice => "Article created successfully." })
    else
      redirect_to("/articles", { :alert => the_article.errors.full_messages.to_sentence })
    end
  end

  def update
    the_id = params.fetch("path_id")
    the_article = Article.where({ :id => the_id }).at(0)

    the_article.title = params.fetch("query_title")
    the_article.summary = params.fetch("query_summary")

    if the_article.valid?
      the_article.save
      redirect_to("/articles/#{the_article.id}", { :notice => "Article updated successfully." } )
    else
      redirect_to("/articles/#{the_article.id}", { :alert => the_article.errors.full_messages.to_sentence })
    end
  end

  def destroy
    the_id = params.fetch("path_id")
    the_article = Article.where({ :id => the_id }).at(0)

    the_article.destroy

    redirect_to("/articles", { :notice => "Article deleted successfully." } )
  end
end
