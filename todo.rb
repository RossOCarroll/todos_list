require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'tilt'
require 'erubis'


configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

helpers do
# Check if the list is complete
  def list_complete?(list)
    list[:todos].size > 0 && list[:todos].all? { |todo| todo[:completed] == true }
  end 

  def list_class(list)
    "complete" if list_complete?(list)
  end

  def todos_remaining_count(list)
    list[:todos].count { |todo| !todo[:completed] }
  end

  def todos_count(list)
    list[:todos].size
  end

  def sort_lists(lists, &block)
    incomplete_lists = {}
    complete_lists = {}

    lists.each_with_index do |list, index|
      if list_complete?(list)
        complete_lists[list] = index
      else
        incomplete_lists[list] = index
      end
    end

    incomplete_lists.each(&block)
    complete_lists.each(&block)
  end

  def sort_todos(todos, &block)
    incomplete_todos = {}
    complete_todos = {}

    todos.each_with_index do |todo, index|
      if todo[:completed]
        complete_todos[todo] = index
      else
        incomplete_todos[todo] = index
      end
    end

    incomplete_todos.each(&block)
    complete_todos.each(&block)
  end
end

before do
  session[:lists] ||= []
end

get '/' do
  redirect '/lists'
end

# View all the lists
get '/lists' do
  @lists = session[:lists]

  erb :lists, layout: :layout
end

# Render the new list form
get '/lists/new' do
  erb :new_list, layout: :layout
end



# Return an error message if the name is invalid. Return nil if name is valid.
def error_for_list_name(name)
  if !(1..100).cover? name.size
    'The list name should be between 1 and 100 characters.'
  elsif session[:lists].any? { |list| list[:name] == name }
    'List name must be unique.'
  end
end

# Return an error message if the todo is invalid. Return nil if name is valid.
def error_for_todo(name)
  if !(1..100).cover? name.size
    'Todo should be between 1 and 100 characters.'
  end
end

# Create a new lists
post '/lists' do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)

  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = 'The list has been created.'
    redirect '/lists'
  end
end

# Displaying a individual todo list

get '/lists/:id' do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]

  erb :list, layout: :layout
end

# Edit an existing todo list

get '/lists/:id/edit' do 
  id = params[:id].to_i
  @list = session[:lists][id]

  erb :edit_list, layout: :layout
end

# Update and existing todo list

post '/lists/:id' do
  list_name = params[:list_name].strip
  id = params[:id].to_i
  @list = session[:lists][id]
  error = error_for_list_name(list_name)

  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @list[:name] = list_name
    session[:success] = 'The list has been updated.'
    redirect "/lists/#{id}"
  end
end

# Delete a list

post '/lists/:id/destroy' do 
  id = params[:id].to_i
  session[:lists].delete_at(id)

  session[:success] = 'The list has been deleted.'
  redirect '/lists'
end

# Add a new todo to a list

post '/lists/:list_id/todos' do
  @list_id = params[:list_id].to_i 
  @list = session[:lists][@list_id]
  text = params[:todo].strip

  error = error_for_todo(text)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @list[:todos] << { name: params[:todo], completed: false }
    session[:success] = "Todo added!"
    redirect "/lists/#{@list_id}"
  end
end

# Delete a todo from a list

post '/lists/:list_id/todo/:todo_id/destroy' do 
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  todo_id = params[:todo_id].to_i

  @list[:todos].delete_at todo_id
  
  session[:success] = "Todo deleted."
  redirect "/lists/#{@list_id}"
end

# Update status a todo as complete

post '/lists/:list_id/todo/:id' do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  todo_id = params[:id].to_i
  is_completed = params[:completed] == "true"

  @list[:todos][todo_id][:completed] = is_completed
  session[:success] = "Todo updated!"

  redirect "/lists/#{@list_id}"
end

# Complete all todos on a list

post '/lists/:id/complete_all' do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]

  @list[:todos].each do |todo|
    todo[:completed] = true
  end
  
  session[:success] = "All todos marked as complete!"
  redirect "/lists/#{@list_id}"
end
