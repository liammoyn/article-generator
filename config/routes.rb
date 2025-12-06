Rails.application.routes.draw do

  get("/", { :controller => "pages", :action => "home" })

  #------------------------------
  # Routes for the Topic resource:

  post("/generate_topic", { :controller => "topics", :action => "generate" })
  # CREATE
  post("/insert_topic", { :controller => "topics", :action => "create" })

  # READ
  get("/topics", { :controller => "topics", :action => "index" })

  get("/topics/:path_id", { :controller => "topics", :action => "show" })

  # UPDATE

  post("/modify_topic/:path_id", { :controller => "topics", :action => "update" })

  # DELETE
  get("/delete_topic/:path_id", { :controller => "topics", :action => "destroy" })

  #------------------------------
  # Routes for the Note resource:

  # CREATE
  post("/insert_note", { :controller => "notes", :action => "create" })

  # READ
  get("/notes", { :controller => "notes", :action => "index" })

  get("/notes/:path_id", { :controller => "notes", :action => "show" })

  # UPDATE

  post("/modify_note/:path_id", { :controller => "notes", :action => "update" })

  # DELETE
  get("/delete_note/:path_id", { :controller => "notes", :action => "destroy" })

  #------------------------------
  # Routes for the Article resource:

  # CREATE
  post("/insert_article", { :controller => "articles", :action => "create" })

  # READ
  get("/articles", { :controller => "articles", :action => "index" })

  get("/articles/:path_id", { :controller => "articles", :action => "show" })

  # UPDATE

  post("/modify_article/:path_id", { :controller => "articles", :action => "update" })

  # DELETE
  get("/delete_article/:path_id", { :controller => "articles", :action => "destroy" })

  #--------------------------------
  # Routes for the Section resource:

  # CREATE
  post("/insert_section", { :controller => "sections", :action => "create" })

  # READ
  get("/sections", { :controller => "sections", :action => "index" })

  get("/sections/:path_id", { :controller => "sections", :action => "show" })

  # UPDATE

  post("/modify_section/:path_id", { :controller => "sections", :action => "update" })

  # DELETE
  get("/delete_section/:path_id", { :controller => "sections", :action => "destroy" })

  #------------------------------
  devise_for :users
end
