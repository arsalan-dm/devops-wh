import { LightningElement,api } from 'lwc';
import ChartJs from '@salesforce/resourceUrl/ChartJs';
import { loadScript } from 'lightning/platformResourceLoader';

export default class ChartExample extends LightningElement {

    @api type = '';
    @api chartData = '';
    @api chartLabels = '';
    @api backgroundColors = '';
    @api chartHeight = '400'; // Default to 400px if not provided
    @api borderColor = ''
    @api borderColour = ''
    @api borderWidth = '1'


    chart;

    renderedCallback() {
        if (this.chart) {
            return; // Chart already initialized
        }
        
        // Load Chart.js library
        loadScript(this, ChartJs)
            .then(() => {
                console.log('✅ Chart.js loaded successfully:', window.Chart);
                this.initializeChart();
            })
            .catch(error => {
                console.error('❌ Error loading Chart.js:', error);
            });
    }
    
    initializeChart() {
        try {
            // Parse chart data
            const parsedData = this.chartData.split(',').map(value => Number(value.trim()));

            // Convert chartLabels into an array of strings
            let parsedLabels = this.chartLabels ? this.chartLabels.split(',').map(label => label.trim()) : [];

            // If no labels are provided, generate default ones
            if (parsedLabels.length === 0 || parsedLabels.length < parsedData.length) {
                parsedLabels = parsedData.map((_, index) => `Label ${index + 1}`);
            }

            // Parse background colors
            const parsedBGColors = this.backgroundColors.split(',').map(color => color.trim());

            // Apply chart height dynamically
            const canvas = this.template.querySelector('canvas');
            if (canvas) {
                canvas.style.height = `${this.chartHeight}px`;
            }

            const ctx = this.template.querySelector('canvas').getContext('2d');
            this.chart = new Chart(ctx, {
                type: this.type, // Define chart type (bar, line, pie, etc.)
                data: {
                    labels: parsedLabels,
                    datasets: [
                        {
                            label: 'Sales Data',
                            data: parsedData,
                            backgroundColor: parsedBGColors,
                            borderColor: this.borderColor,
                            borderWidth: this.borderWidth
                        }
                    ]
                },
                options: {
                    responsive: true,
                    legend: {
                            display: true, // ✅ Hides the legend
                            position: 'right',
                            align: 'left',
                            labels: {
                                boxWidth: 20,
                                padding: 10
                            } 
                        },
                    scales: {
                        y: {
                            beginAtZero: true
                        }
                    }
                }
            });

            console.log('✅ Legend display setting:', this.chart.options.legend.display);
            console.log('✅ Chart created successfully:', this.chart);

        } catch (error) {
            console.error('❌ Error initializing chart:', error.message || error);
        }
    }
}