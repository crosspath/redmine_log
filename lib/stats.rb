# require Rails.root.join('plugins', 'redmine_log', 'init.rb').to_s

module Stats
  def self.included(base)
    base.class_eval do
      # Examples:
      # Log.interval(Date.yesterday).views
      # Log.interval(Date.parse('2015-05-11'), Date.parse('2015-05-17')).visits

      # Просмотры
      scope :views, lambda { count }

      # Визиты
      # test: Log.where.not(first_id: nil).where(:created_at => from .. to).pluck(:first_id).uniq.size
      scope :visits, lambda { select('count(first_id) as first_id').where('id = first_id')[0].first_id }

      # Посетители
      # test: Log.where.not(user_id: nil).where(:created_at => from .. to).pluck(:user_id).uniq.size
      scope :users, lambda { select('count(distinct user_id) as user_id')[0].user_id }

      # Контроллеры
      scope :controllers, lambda { select(:controller).uniq.pluck(:controller) }

      scope :popular_controllers, lambda { |lim = 0|
                                  logs = count_and_sort(controllers, :top => lim) do |x|
                                    where(:controller => x).views
                                  end
                                  Hash[*logs.flatten]
                                }

      # Контроллеры страниц – источников переходов
      scope :referer_controllers, lambda { select(:referer_controller).uniq.pluck(:referer_controller) }

      scope :popular_referer_controllers, lambda { |lim = 0|
                                          logs = count_and_sort(referer_controllers, :top => lim) do |x|
                                            where(:referer_controller => x).views
                                          end
                                          Hash[*logs.flatten]
                                        }

      # Пути
      scope :paths, lambda {
                    ids = select(:first_id).uniq.pluck(:first_id)
                    result = {}
                    ids.each { |id| result[id] = where(:first_id => id).order(:id) }
                    result
                  }

      # Наиболее посещаемые страницы
      # options - count: 20, group_by: :query | :controller | :controller_and_action
      scope :popular, lambda { |options = {}|
                      lim = options.delete(:count) || 20
                      grp = options.delete(:group_by) || :query
                      grouped = case grp
                                  when :query
                                    all.group_by(&:query)
                                  when :controller, :controller_and_action
                                    all.group_by do |x|
                                      begin
                                        params = x.parameters
                                        if params.present?
                                          params = JSON.parse(params)
                                          params['controller'] + (grp == :controller ? '' : "##{params['action']}")
                                        else
                                          nil
                                        end
                                      rescue JSON::ParserError
                                        nil
                                      end
                                    end
                                end
                      count_and_sort(grouped, :top => lim) { |x| x.size }
                    }

      # Страницы входа
      scope :enter_pages, lambda { where('first_id = id') }

      # Страницы выхода
      scope :exit_pages, lambda {
                         ids = select(:first_id).uniq.pluck(:first_id)
                         ids.map { |id| where(:first_id => id).order(:id => :desc).first }
                       }

      def count_and_sort(array, options = {})
        top = options[:top]
        a = array.map { |x| [x, yield(x)] }.sort_by { |x| x[1] }
        a = a.reverse[0 ... top] if top && top > 0
        a
      end
    end
  end
end

ActionDispatch::Callbacks.to_prepare do
  Log.send(:include, Stats) unless Log.included_modules.include?(Stats)
end
