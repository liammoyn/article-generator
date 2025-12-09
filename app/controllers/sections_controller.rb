class SectionsController < ApplicationController
  def index
    matching_sections = Section.all

    @list_of_sections = matching_sections.order({ :created_at => :desc })

    render({ :template => "section_templates/index" })
  end

  def show
    the_id = params.fetch("path_id")

    matching_sections = Section.where({ :id => the_id })

    @the_section = matching_sections.at(0)

    render({ :template => "section_templates/show" })
  end

  def generate
    section_id = params.fetch("path_id")
    the_section = Section.where({ :id => section_id }).at(0)
    the_article = Article.where({ :id => the_section.article_id }).at(0)
    topic_id = the_article.topic_id

    # TODO: Generate section content based on notes, article summary, and other sections
    section_generation_system_prompt = "You are writing a section of an article. This section should be between 100 and 500 words and use clear and descriptive language. The user will provide a summary of the article, the name of this section, and any note documents used as sources for the article. Additionally, the user may include some parts of the section they have already written. If the user does provide content for the section, try to touch on the same ideas. You should respond with just the section content and nothing else, do not include the section title. Only write about things that are directly relevant to the section title. Do not write anything that is outside of the scope of the section."

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

    user_prompt = "Article summary:\n#{the_article.summary}\n\nSection Title:\n#{the_section.name}\n\nUser Notes:\n#{note_content_string}\n\nExisting Section Content:\n#{the_section.content}"

    c = AI::Chat.new
    c.system(section_generation_system_prompt)
    c.user(user_prompt, files: note_file_urls)

    ai_response = c.generate!
    the_section.content = ai_response[:content]

    if the_section.valid?
      the_section.save
      redirect_to("/articles/#{the_section.article_id}", { :note => "Section created successfully" } )
    else
      redirect_back(:fallback_location => "/", :alert => the_section.errors.full_messages.to_sentence)
    end
  end

  def create
    the_section = Section.new
    the_section.name = params.fetch("query_name")
    the_section.article_id = params.fetch("query_article_id")
    the_section.placement = params.fetch("query_placement")
    the_section.content = params.fetch("query_content")

    if the_section.valid?
      the_section.save
      redirect_to("/articles/#{the_section.article_id}", { :note => "Section created successfully" } )
    else
      redirect_back(:fallback_location => "/", :alert => the_section.errors.full_messages.to_sentence)
    end
  end

  def update
    the_id = params.fetch("path_id")
    the_section = Section.where({ :id => the_id }).at(0)

    the_section.name = params.fetch("query_name")
    # the_section.placement = params.fetch("query_placement")
    the_section.content = params.fetch("query_content")

    if the_section.valid?
      the_section.save
      redirect_to("/articles/#{the_section.article_id}", { :note => "Section updated successfully" } )
    else
      redirect_back(:fallback_location => "/", :alert => the_section.errors.full_messages.to_sentence)
    end
  end

  def destroy
    the_id = params.fetch("path_id")
    the_section = Section.where({ :id => the_id }).at(0)
    article_id = the_section.article_id

    the_section.destroy

    redirect_to("/articles/#{article_id}", { :note => "Section updated successfully" } )
  end
end
