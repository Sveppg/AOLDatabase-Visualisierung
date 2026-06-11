#include "plots.hpp"
#include <iostream>

int main() {
    std::cout << "Generating plots...\n";
    //plot01_ied_count();
    //plot01_ied_per_month();
    //plot02_politicians_iraq_bar();
    //plot03_themenvorkommen();
    //plot04_which_actors();
    //plot05_veteran_count();
    //plot05_veteran_pie();
    //plot06_iraq_war();
    //plot07_wmd_search();
    //plot_iraq_city_over_time("baghdad");  
    
    //Plot 8
    //plot_iraq_city_over_time("basra");        
    //plot_iraq_city_over_time("iraq");        
    //plot_iraq_city_over_time("mosul"); 
    
    

    plot10_iraq_world_pairs_top10();

    std::cout << "Done. PNG files written to current directory.\n";
    return 0;
}
