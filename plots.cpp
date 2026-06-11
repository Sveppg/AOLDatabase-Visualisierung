#include "plots.hpp"
#include "db.hpp"
#include <matplot/matplot.h>
#include <pqxx/pqxx>

#include <string>
#include <vector>
#include <iostream>
#include <stdexcept>

/* Helper for fetching grid information*/
static void fetch_label_value(
    const std::string& sql,
    std::vector<std::string>& labels,
    std::vector<double>& values
) {
    auto db = make_db();
    pqxx::work txn{db};
    auto r = txn.exec(sql);

    labels.clear();
    values.clear();
    for (auto row : r) {
        labels.emplace_back(row[0].c_str());
        values.push_back(row[1].as<double>());
    }
}

static void fetch_series_y(
    const std::string& sql,
    std::vector<double>& y
) {
    auto db = make_db();
    pqxx::work txn{db};
    auto r = txn.exec(sql);

    y.clear();
    for (auto row : r) {
        y.push_back(row[1].as<double>());
    }
}

static void save_bar(
    const std::vector<std::string>& labels,
    const std::vector<double>& values,
    const std::string& title_str,
    const std::string& outfile_png,
    int width = 1400,
    int height = 1000

) {
    using namespace matplot;
    auto fig = figure(true);
    fig->size(width,height);
    bar(values);
    xticks(iota(1, (int)labels.size()));
    xticklabels(labels);
    xtickangle(45);
    title(title_str);
    ylabel("Count");
    grid(on);
    save(outfile_png);
}

static void save_pie(
    const std::vector<std::string>& labels,
    const std::vector<double>& values,
    const std::string& title_str,
    const std::string& outfile_png,
    int width = 1400,
    int height = 1000
) {
    using namespace matplot;

    auto fig = figure(true);
    fig->size(width, height);

    pie(values);
    legend(labels);
    title(title_str);

    save(outfile_png);
}

static void save_line_indexed(
    const std::vector<double>& y,
    const std::string& title_str,
    const std::string& outfile_png
) {
    using namespace matplot;
    std::vector<double> x;
    x.reserve(y.size());
    for (size_t i = 0; i < y.size(); ++i) x.push_back((double)i);

    auto fig = figure(true);
    plot(x, y);
    title(title_str);
    xlabel("Time index");
    ylabel("Count");
    grid(on);
    save(outfile_png);
}


static void save_line_with_labels(
    const std::vector<std::string>& labels,
    const std::vector<double>& y,
    const std::string& title_str,
    const std::string& outfile_png,
    int width = 1600,
    int height = 1000
) {
    using namespace matplot;

    std::vector<double> x;
    x.reserve(y.size());
    for (size_t i = 0; i < y.size(); ++i)
        x.push_back(static_cast<double>(i));

    auto fig = figure(true);
    fig->size(width, height);

    plot(x, y);
    title(title_str);
    ylabel("Count");
    grid(on);

    xticks(x);
    xticklabels(labels);
    xtickangle(45);   // wichtig für Lesbarkeit

    save(outfile_png);
}


// =======================================================
void plot01_ied_count() {
 const std::string sql =
        "WITH stats AS ("
        "  SELECT "
        "    COUNT(*) FILTER ("
        "      WHERE query ~* '(^|[^a-z0-9])(ied|improvised explosive device|roadside bomb)([^a-z0-9]|$)'"
        "    ) AS mention_count, "
        "    COUNT(*) AS total_queries "
        "  FROM aol_raw"
        ") "
        "SELECT 'IED-related queries' AS label, mention_count::double precision AS value FROM stats "
        "UNION ALL "
        "SELECT 'Other queries' AS label, (total_queries - mention_count)::double precision AS value FROM stats;";
 
    std::vector<std::string> labels;
    std::vector<double> values;
    fetch_label_value(sql, labels, values);
    save_bar(labels, values, "IED-related Queries (share)", "plot01_ied_share.png");
}

void plot01_ied_per_month() {
    const std::string sql =
        "SELECT to_char(date_trunc('month', querytime), 'YYYY-MM') AS month, "
        "       COUNT(*)::double precision AS cnt "
        "FROM aol_raw "
        "WHERE query ~* '(^|[^a-z0-9])(ied|improvised explosive device|roadside bomb)([^a-z0-9]|$)' "
        "GROUP BY 1 "
        "ORDER BY 1;";

    std::vector<std::string> labels;
    std::vector<double> values;
    fetch_label_value(sql, labels, values);
    save_bar(labels, values, "IED-related Queries per Month", "plot01_ied_per_month.png");
}

void plot02_politicians_iraq_bar() {
    const std::string sql =
        "WITH counts AS ( "
        "  SELECT a.name AS label, COUNT(*)::double precision AS value "
        "  FROM aol_raw ar "
        "  JOIN actor a ON ar.query ~* ("
        "    '(^|[^a-zA-Z0-9])' || regexp_replace(a.name, ' ', '\\\\s+', 'g') || '([^a-zA-Z0-9]|$)'"
        "  ) "
        "  JOIN keyword k ON k.category = 'IRAQ_LOCATION' AND ar.query ~* ("
        "    '(^|[^a-zA-Z0-9])' || regexp_replace(k.word, ' ', '\\\\s+', 'g') || '([^a-zA-Z0-9]|$)'"
        "  ) "
        "  WHERE a.type = 'Politician' "
        "  GROUP BY a.name "
        "), topn AS ( "
        "  SELECT label, value FROM counts ORDER BY value DESC LIMIT 6 "
        "), other AS ( "
        "  SELECT 'Other' AS label, COALESCE(SUM(value),0)::double precision AS value "
        "  FROM counts WHERE label NOT IN (SELECT label FROM topn) "
        ") "
        "SELECT label, value FROM topn "
        "UNION ALL "
        "SELECT label, value FROM other;";

    std::vector<std::string> labels;
    std::vector<double> values;
    fetch_label_value(sql, labels, values);
    save_bar(labels, values, "Politicians mentioned with Iraq (Top 10)", "plot02_politicians_iraq_bar.png");
}

void plot03_themenvorkommen() {
    const std::string sql =
        "SELECT "
        "  (k.category || ': ' || k.word) AS label, "
        "  COUNT(*)::double precision AS value "
        "FROM aol_raw ar "
        "JOIN keyword k "
        "  ON ar.query ~* ("
        "    '(^|[^a-zA-Z0-9])' || regexp_replace(k.word, ' ', '\\\\s+', 'g') || '([^a-zA-Z0-9]|$)'"
        "  ) "
        "GROUP BY k.word, k.category "
        "ORDER BY value DESC "
        "LIMIT 15;";

    std::vector<std::string> labels;
    std::vector<double> values;
    fetch_label_value(sql, labels, values);

    save_bar(labels, values, "Most frequent keywords (Top 15)", "plot03_topics_top15.png");
}

void plot04_which_actors() {
    const std::string sql =
        "SELECT "
        "  (a.type || ': ' || a.name) AS label, "
        "  COUNT(*)::double precision AS value "
        "FROM aol_raw ar "
        "JOIN actor a "
        "  ON ar.query ~* ("
        "    '(^|[^a-zA-Z0-9])' || "
        "    regexp_replace(a.name, ' ', '\\\\s+', 'g') || "
        "    '([^a-zA-Z0-9]|$)'"
        "  ) "
        "GROUP BY a.name, a.type "
        "ORDER BY value DESC "
        "LIMIT 15;";

    std::vector<std::string> labels;
    std::vector<double> values;
    fetch_label_value(sql, labels, values);

    save_bar(labels, values, "Top Actors (mentions)", "plot04_top_actors.png");
}

void plot05_veteran_count() {
    const std::string sql =
        "WITH veteran_queries AS ( "
        "  SELECT DISTINCT ar.anonid, ar.querytime, ar.query "
        "  FROM aol_raw ar "
        "  WHERE EXISTS ( "
        "    SELECT 1 FROM keyword k "
        "    WHERE k.category='VETERAN' "
        "      AND ar.query ~* ( "
        "        '(^|[^A-Za-z0-9])' || "
        "        regexp_replace(k.word, ' ', '\\\\s+', 'g') || "
        "        '([^A-Za-z0-9]|$)' "
        "      ) "
        "  ) "
        "), "
        "veteran_help_queries AS ( "
        "  SELECT * "
        "  FROM veteran_queries "
        "  WHERE query ~* "
        "    '(^|[^A-Za-z0-9])"
        "    (help|support|therapy|counsel(ing)?|clinic|hospital|va|hotline|treatment)"
        "    ([^A-Za-z0-9]|$)' "
        ") "
        "SELECT 'Veteran-related queries' AS label, "
        "       COUNT(*)::double precision AS value "
        "FROM veteran_queries "
        "UNION ALL "
        "SELECT 'Veteran help queries' AS label, "
        "       COUNT(*)::double precision AS value "
        "FROM veteran_help_queries;";

    std::vector<std::string> labels;
    std::vector<double> values;
    fetch_label_value(sql, labels, values);

    save_bar(labels, values, "Veteran Help Searches", "plot05_veteran_search.png");
}

void plot05_veteran_pie() {
    const std::string sql =
        "WITH veteran_queries AS ( "
        "  SELECT DISTINCT ar.anonid, ar.querytime, ar.query "
        "  FROM aol_raw ar "
        "  WHERE EXISTS ( "
        "    SELECT 1 FROM keyword k "
        "    WHERE k.category='VETERAN' "
        "      AND ar.query ~* ( "
        "        '(^|[^A-Za-z0-9])' || "
        "        regexp_replace(k.word, ' ', '\\\\s+', 'g') || "
        "        '([^A-Za-z0-9]|$)' "
        "      ) "
        "  ) "
        "), "
        "veteran_help_queries AS ( "
        "  SELECT * FROM veteran_queries "
        "  WHERE query ~* '(^|[^A-Za-z0-9])(help|support|therapy|counsel(ing)?|clinic|hospital|va|hotline|treatment)([^A-Za-z0-9]|$)' "
        "), "
        "counts AS ( "
        "  SELECT "
        "    (SELECT COUNT(*) FROM veteran_queries)      AS related, "
        "    (SELECT COUNT(*) FROM veteran_help_queries) AS help "
        ") "
        "SELECT 'Help-seeking' AS label, help::double precision AS value FROM counts "
        "UNION ALL "
        "SELECT 'Other veteran-related' AS label, (related - help)::double precision AS value FROM counts;";

    std::vector<std::string> labels;
    std::vector<double> values;
    fetch_label_value(sql, labels, values);

    save_pie(labels, values, "Veteran queries: help vs other", "plot05_veteran_pie.png", 1600, 1000);
}

void plot06_iraq_war() {
    const std::string sql =
        "WITH iraq_queries AS ( "
        "  SELECT DISTINCT ar.anonid, ar.querytime, ar.query "
        "  FROM aol_raw ar "
        "  WHERE EXISTS ( "
        "    SELECT 1 FROM keyword k "
        "    WHERE k.category = 'IRAQ_LOCATION' "
        "      AND ar.query ~* ( "
        "        '(^|[^a-zA-Z0-9])' || "
        "        regexp_replace(k.word, ' ', '\\\\s+', 'g') || "
        "        '([^a-zA-Z0-9]|$)' "
        "      ) "
        "  ) "
        "), "
        "iraq_war_queries AS ( "
        "  SELECT DISTINCT iq.anonid, iq.querytime, iq.query "
        "  FROM iraq_queries iq "
        "  WHERE EXISTS ( "
        "    SELECT 1 FROM keyword k2 "
        "    WHERE k2.category IN ('WAR','WEAPON') "
        "      AND iq.query ~* ( "
        "        '(^|[^a-zA-Z0-9])' || "
        "        regexp_replace(k2.word, ' ', '\\\\s+', 'g') || "
        "        '([^a-zA-Z0-9]|$)' "
        "      ) "
        "  ) "
        "), "
        "counts AS ( "
        "  SELECT "
        "    (SELECT COUNT(*) FROM iraq_queries) AS total_iraq, "
        "    (SELECT COUNT(*) FROM iraq_war_queries) AS war_iraq "
        ") "
        "SELECT 'Iraq + War/Weapon' AS label, war_iraq::double precision AS value FROM counts "
        "UNION ALL "
        "SELECT 'Iraq other' AS label, (total_iraq - war_iraq)::double precision AS value FROM counts;";

    std::vector<std::string> labels;
    std::vector<double> values;
    fetch_label_value(sql, labels, values);

    save_pie(labels, values, "Iraq queries: war/weapon vs other", "plot06_iraq_war.png", 1600, 1000);
}

void plot07_wmd_search(){
    const std::string sql =
        "SELECT "
        "  k.word AS label, "
        "  COUNT(*)::double precision AS value "
        "FROM aol_raw ar "
        "JOIN keyword k "
        "  ON k.category = 'WEAPON' "
        " AND ar.query ~* ( "
        "   '(^|[^A-Za-z0-9])' || "
        "   regexp_replace(k.word, ' ', '\\\\s+', 'g') || "
        "   '([^A-Za-z0-9]|$)' "
        " ) "
        "GROUP BY k.word "
        "ORDER BY value DESC;";

    std::vector<std::string> labels;
    std::vector<double> values;
    fetch_label_value(sql, labels, values);

    save_bar(labels, values, "Weapon/WMD keyword mentions", "plot_wmd_mentions.png", 1600, 1000);
}

void plot_iraq_city_over_time(const std::string& city) { //Frage 8: 
    const std::string sql =
        "SELECT "
        "  to_char(date_trunc('month', ar.querytime), 'YYYY-MM') AS label, "
        "  COUNT(*)::double precision AS value "
        "FROM aol_raw ar "
        "JOIN keyword k "
        "  ON k.category = 'IRAQ_LOCATION' "
        " AND k.word = '" + city + "' "
        " AND ar.query ~* ("
        "   '(^|[^A-Za-z0-9])' || "
        "   regexp_replace(k.word, ' ', '\\\\s+', 'g') || "
        "   '([^A-Za-z0-9]|$)'"
        " ) "
        "GROUP BY 1 "
        "ORDER BY 1;";

    std::vector<std::string> months;
    std::vector<double> counts;

    fetch_label_value(sql, months, counts);

    save_line_with_labels(
        months,
        counts,
        "Mentions of " + city + " over time",
        "plot_iraq_" + city + "_timeline.png"
    );
}

void plot10_iraq_world_pairs_top10() {
    const std::string sql =
        "WITH iraq_hits AS ( "
        "  SELECT ar.anonid, ar.querytime, ar.query, k.word AS iraq_city "
        "  FROM aol_raw ar "
        "  JOIN keyword k "
        "    ON k.category = 'IRAQ_LOCATION' "
        "   AND ar.query ~* ( "
        "     '(^|[^A-Za-z0-9])' || "
        "     regexp_replace(k.word, ' ', '\\\\s+', 'g') || "
        "     '([^A-Za-z0-9]|$)' "
        "   ) "
        "), "
        "world_hits AS ( "
        "  SELECT ar.anonid, ar.querytime, ar.query, k.word AS world_city "
        "  FROM aol_raw ar "
        "  JOIN keyword k "
        "    ON k.category = 'WORLD_LOCATION' "
        "   AND ar.query ~* ( "
        "     '(^|[^A-Za-z0-9])' || "
        "     regexp_replace(k.word, ' ', '\\\\s+', 'g') || "
        "     '([^A-Za-z0-9]|$)' "
        "   ) "
        "), "
        "pairs AS ( "
        "  SELECT ih.iraq_city, wh.world_city "
        "  FROM iraq_hits ih "
        "  JOIN world_hits wh "
        "    ON ih.anonid = wh.anonid "
        "   AND ih.querytime = wh.querytime "
        "   AND ih.query = wh.query "
        ") "
        "SELECT (iraq_city || ' + ' || world_city) AS label, "
        "       COUNT(*)::double precision AS value "
        "FROM pairs "
        "GROUP BY iraq_city, world_city "
        "ORDER BY value DESC "
        "LIMIT 10;";

    std::vector<std::string> labels;
    std::vector<double> values;
    fetch_label_value(sql, labels, values);

    save_bar(labels, values,
             "Iraq + World location pairs (Top 10, same query)",
             "plot10_iraq_world_pairs_top10.png",
             1800, 1100);
}
