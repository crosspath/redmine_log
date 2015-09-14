# require Rails.root.join('plugins', 'redmine_log', 'init.rb').to_s

module LogPlugin
  module Stats
    extend ActiveSupport::Concern
    
    # Examples:
    # Log.interval(Date.yesterday).views
    # Log.interval(Date.parse('2015-05-11'), Date.parse('2015-05-17')).visits

    class_methods do
      # Просмотры
      def views
        count
      end

      # Визиты
      # test: Log.where.not(first_id: nil).where(:created_at => from .. to).pluck(:first_id).uniq.size
      def visits
        select(:first_id).where('id = first_id').count
      end

      # Посетители
      # test: Log.where.not(user_id: nil).where(:created_at => from .. to).pluck(:user_id).uniq.size
      def users
        select(:user_id).uniq.count
      end

      # Контроллеры
      def controllers
        select(:controller).uniq.pluck(:controller).compact
      end

      def popular_controllers(lim = 0)
        logs = sort_by_count(controllers, top: lim, keep_count: true) do |x|
          where(controller: x).views
        end
        logs.to_h
      end

      # Контроллеры страниц – источников переходов
      def referer_controllers
        select(:referer_controller).uniq.pluck(:referer_controller).compact
      end

      def popular_referer_controllers(lim = 0)
        logs = sort_by_count(referer_controllers, top: lim, keep_count: true) do |x|
          where(referer_controller: x).views
        end
        logs.to_h
      end

      # Пути
      def paths
        ids = select(:first_id).uniq.pluck(:first_id).compact
        result = {}
        ids.each { |id| result[id] = where(first_id: id).order(:created_at) }
        result
      end

      # Наиболее посещаемые страницы
      # options - count: 20, group_by: :query | :controller | :controller_and_action
      def popular(options = {})
        lim = options.delete(:count) || 20
        grp = options.delete(:group_by) || :query
        grp = grp.to_sym
        grouped = case grp
                    when :query, :controller
                      all.group_by(&grp)
                    when :controller_and_action
                      all.group_by do |x|
                        params = x.safe_parse_parameters
                        params && "#{params['controller']}##{params['action']}"
                      end
                    else
                      raise 'Invalid "group_by" value'
                  end
        sort_by_count(grouped, top: lim, &:size)
      end

      # Страницы входа
      def enter_pages
        where('first_id = id')
      end

      # Страницы выхода
      def exit_pages
        ids = select(:first_id).uniq.pluck(:first_id)
        ids.map { |id| order(created_at: :desc).find_by(first_id: id) }
      end

      def sort_by_count(array, options = {})
        top = options.delete(:top)
        keep_count = options.delete(:keep_count)
        puts keep_count.inspect
        # посчитать и отсортировать
        a = array.map { |x| [x, yield(x)] }.sort_by { |_, count| count }
        # отбросить количество из результата
        a.map! { |key_and_array, _| key_and_array } unless keep_count
        a = a.reverse[0 ... top] if top && top > 0
        a
      end
    end
  end
end

ActionDispatch::Callbacks.to_prepare do
  Log.send(:include, LogPlugin::Stats) unless Log.included_modules.include?(LogPlugin::Stats)
end
