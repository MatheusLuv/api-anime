require 'pg'
require 'httparty'
require 'time'

# Conexão com PostgreSQL
class DBConnector
  def initialize
    @conn = PG.connect(
      host: 'localhost',
      port: 5432,
      dbname: 'danbooru_demo',
      user: 'postgres',
      password: 'postgres'
    )
  end

  def exec_params(sql, params = [])
    @conn.exec_params(sql, params)
  end

  def close
    @conn.close if @conn && !@conn.finished?
  end
end

# Classe para consumir API Danbooru
class DanbooruAPI
  BASE = "https://danbooru.donmai.us"

  def fetch_posts(tag, page = 1, limit = 20)
    url = "#{BASE}/posts.json?tags=#{tag}&page=#{page}&limit=#{limit}"
    resp = HTTParty.get(url)
    if resp.success?
      resp.parsed_response
    else
      puts "Erro HTTP #{resp.code}"
      []
    end
  end
end

# Classe para salvar/listar no banco
class PostRepository
  def initialize(db)
    @db = db
    @upsert_sql = <<~SQL
      INSERT INTO danbooru_posts
        (api_id, tags, image_url, creator, score, file_ext, created_at)
      VALUES ($1,$2,$3,$4,$5,$6,$7)
      ON CONFLICT (api_id) DO NOTHING
    SQL
  end

  def save(post)
    api_id = post["id"]
    tags = post["tag_string"]
    image_url = post["large_file_url"] || post["file_url"] || post["preview_file_url"]
    creator = post["uploader_name"] || "desconhecido"
    score = post["score"]
    file_ext = post["file_ext"]
    created_at = post["created_at"] ? Time.parse(post["created_at"]) : nil

    @db.exec_params(@upsert_sql, [
      api_id,
      tags,
      image_url.to_s,
      creator.to_s,
      score.to_i,
      file_ext.to_s,
      created_at
    ])
  end

  def clear_all
    @db.exec_params("DELETE FROM danbooru_posts")
  end

  def all(limit = nil, tag = nil)
    sql = "SELECT * FROM danbooru_posts"
    params = []

    if tag
      sql += " WHERE tags ILIKE $1"
      params << "%#{tag}%"
    end

    sql += " ORDER BY api_id DESC"
    sql += " LIMIT #{limit}" if limit
    @db.exec_params(sql, params)
  end
end

# Classe principal do app
class MeuAppDanbooru
  def initialize
    @db = DBConnector.new
    @api = DanbooruAPI.new
    @repo = PostRepository.new(@db)
  end

  def fetch_and_store(tag, max_pages = 2, per_page = 20)
    puts "Buscando posts com tag '#{tag}'..."
    
    # Limpa fetch anterior
    @repo.clear_all

    (1..max_pages).each do |page|
      posts = @api.fetch_posts(tag, page, per_page)
      break if posts.empty?
      puts "Página #{page}: #{posts.size} posts."
      posts.each { |p| @repo.save(p) }
    end
    puts "Dados salvos no banco!"
  end

  def list(limit = 10, tag = nil)
    rows = @repo.all(limit, tag).to_a
    rows.each do |row|
      puts "------------------------------"
      puts "ID: #{row['api_id']}"
      puts "Tags: #{row['tags']}"
      puts "Artista: #{row['creator'] || 'desconhecido'}"
      puts "Imagem: #{row['image_url']}"
      puts "------------------------------"
    end
    puts "(Mostrando #{rows.size} registros)"
  end

  def close
    @db.close
  end
end

# CLI simples
if __FILE__ == $0
  app = MeuAppDanbooru.new
  case ARGV[0]
  when "fetch"
    tag = ARGV[1] || "anime"
    pages = ARGV[2] ? ARGV[2].to_i : 1
    app.fetch_and_store(tag, pages)
  when "list"
    count = ARGV[1] ? ARGV[1].to_i : 10
    app.list(count, tag)
  end
  app.close
end
