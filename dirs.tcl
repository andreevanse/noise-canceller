# Скрипт формирует требуемые директории согласно шаблону, описанному ниже, и предоставляет переменные для использования в тестбенчах 
# ROOT_DIR  будет считаться та директория из которой запущен скрипт.
# 
# $ROOT_DIR/fpga           # исходники ПЛИС
# $ROOT_DIR/qproj          # файлы Quartus
# $ROOT_DIR/subproj        # подпроекты Quartus для тестирования отдельных компонентов
# $ROOT_DIR/test           # тесты для модулей
# $ROOT_DIR/sim            # директория для временных файлов симуляции (для каждого теста лучше формировать свою поддиректорию)
#
# Файл обязательно запускать через команду "source", а не команду "do" из-за того, что при вызове "do" не сохраняется путь запуска команды

set ROOT_DIR [file dirname [file normalize [info script]]]
cd $ROOT_DIR

set SIM_DIR "$ROOT_DIR/sim"
if {![file exists $SIM_DIR]} {
    file mkdir $SIM_DIR
}

set SOURCE_DIR "$ROOT_DIR/fpga"
if {![file exists $SOURCE_DIR]} {
    file mkdir $SOURCE_DIR
}

set TEST_DIR "$ROOT_DIR/test"
if {![file exists $TEST_DIR]} {
    file mkdir $TEST_DIR
}

set QPROJ_DIR "$ROOT_DIR/qproj"
if {![file exists $QPROJ_DIR]} {
    file mkdir $QPROJ_DIR
}

set SUBPROJ_DIR "$ROOT_DIR/subproj/fpga"
if {![file exists $SUBPROJ_DIR]} {
    file mkdir $SUBPROJ_DIR
}

