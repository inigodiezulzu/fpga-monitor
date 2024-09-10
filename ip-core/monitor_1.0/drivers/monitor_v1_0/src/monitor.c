

/***************************** Include Files *******************************/
#include "monitor.h"
#include "xil_io.h"

/************************** Function Definitions ***************************/
void MONITOR_config_vref(u32 BaseAddress){
    MONITOR_mWriteReg(BaseAddress, MONITOR_S00_AXI_SLV_REG0_OFFSET, PUM_CONFIG_VREF);
}
void MONITOR_config_2vref(u32 BaseAddress){
    MONITOR_mWriteReg(BaseAddress, MONITOR_S00_AXI_SLV_REG0_OFFSET, PUM_CONFIG_2VREF);
}
void MONITOR_start(u32 BaseAddress){
    while( (MONITOR_mReadReg(BaseAddress, MONITOR_S00_AXI_SLV_REG0_OFFSET) & PUM_BUSY) > 0 );
    MONITOR_mWriteReg(BaseAddress, MONITOR_S00_AXI_SLV_REG0_OFFSET, PUM_START);
}
void MONITOR_stop(u32 BaseAddress){
    MONITOR_mWriteReg(BaseAddress, MONITOR_S00_AXI_SLV_REG0_OFFSET, PUM_STOP);  // Se carga axi_sniffer_enable, por lo que no hará trigger hasta que no se ponga de nuevo la mascara
}
void MONITOR_mask(u32 BaseAddress, u32 mask){
    MONITOR_mWriteReg(BaseAddress, MONITOR_S00_AXI_SLV_REG3_OFFSET, mask);
}
void MONITOR_axi_mask(u32 BaseAddress, u32 axi_mask){
    MONITOR_mWriteReg(BaseAddress, MONITOR_S00_AXI_SLV_REG2_OFFSET, axi_mask);                     // Write axi mask to register
    MONITOR_mWriteReg(BaseAddress, MONITOR_S00_AXI_SLV_REG0_OFFSET, PUM_AXI_SNIFFER_ENABLE_IN);    // Enable axi sniffing in register
}
u32 MONITOR_consumption_count(u32 BaseAddress){
    return MONITOR_mReadReg(BaseAddress, MONITOR_S00_AXI_SLV_REG1_OFFSET);
}
u32 MONITOR_busy(u32 BaseAddress){
    return ((MONITOR_mReadReg(BaseAddress, MONITOR_S00_AXI_SLV_REG0_OFFSET) & PUM_BUSY) > 0);
}
u32 MONITOR_done(u32 BaseAddress){
    return ((MONITOR_mReadReg(BaseAddress, MONITOR_S00_AXI_SLV_REG0_OFFSET) & PUM_DONE) > 0);
}
u32 MONITOR_power_utilization(u32 BaseAddress){
    return MONITOR_mReadReg(BaseAddress, MONITOR_S00_AXI_SLV_REG2_OFFSET) + 1;
}
u32 MONITOR_traces_utilization(u32 BaseAddress){
    return MONITOR_mReadReg(BaseAddress, MONITOR_S00_AXI_SLV_REG3_OFFSET) + 1;
}
u32 MONITOR_power_errors(u32 BaseAddress){
    return MONITOR_mReadReg(BaseAddress, MONITOR_S00_AXI_SLV_REG0_OFFSET) >> PUM_POWER_ERRORS_OFFSET;
}

// Every reg0 writing is overwriting its actual value, its intended, each action excludes the others
