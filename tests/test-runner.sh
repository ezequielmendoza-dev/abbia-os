#!/usr/bin/env bash

# ==============================================================================
# test-runner.sh — ai-agents OS Automated Test Suite
# ==============================================================================
# Suite de pruebas automatizadas e integrales para verificar el correcto
# funcionamiento de todos los scripts y herramientas de ai-agents en un entorno
# temporal aislado.
# ==============================================================================

set -euo pipefail

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

TESTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$TESTS_DIR/.." && pwd )"
SCRIPTS_DIR="$REPO_ROOT/scripts"

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

assert_success() {
    local desc="$1"
    shift
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -n "  [TEST $TOTAL_TESTS] $desc ... "
    if "$@" >/dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}FAIL${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

assert_failure() {
    local desc="$1"
    shift
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -n "  [TEST $TOTAL_TESTS] $desc ... "
    if "$@" >/dev/null 2>&1; then
        echo -e "${RED}FAIL (se esperaba fallo)${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    else
        echo -e "${GREEN}PASS (falló como se esperaba)${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    fi
}

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}   🧪 Suite de Pruebas Automatizadas — ai-agents    ${NC}"
echo -e "${BLUE}====================================================${NC}"
echo -e "Repositorio: ${YELLOW}$REPO_ROOT${NC}\n"

# Crear entorno temporal aislado
TMP_TEST_DIR=$(mktemp -d -t ai_agents_test_XXXXXX)
trap 'rm -rf "$TMP_TEST_DIR"' EXIT

# Configurar repositorio git ficticio en TMP_TEST_DIR
cd "$TMP_TEST_DIR"
git init --quiet
git config user.name "AI Agents Test Runner"
git config user.email "test@ai-agents.local"

# Simular submódulo en .ai/agents
mkdir -p .ai
ln -s "$REPO_ROOT" .ai/agents

# ------------------------------------------------------------------------------
# 1. Test setup-ide.sh
# ------------------------------------------------------------------------------
echo -e "${BLUE}--- 1. Testing setup-ide.sh ---${NC}"

assert_success "setup-ide.sh --auto inicializa la estructura .ai/ básica" \
    bash "$SCRIPTS_DIR/setup-ide.sh" --auto

assert_success ".ai/context.md fue creado correctamente" \
    test -f "$TMP_TEST_DIR/.ai/context.md"

assert_success ".ai/knowledge-graph.yaml fue creado correctamente" \
    test -f "$TMP_TEST_DIR/.ai/knowledge-graph.yaml"

assert_success ".ai/memory/workflow-log.md fue creado correctamente" \
    test -f "$TMP_TEST_DIR/.ai/memory/workflow-log.md"

assert_success ".ai/memory/decisions-catalog.md ya no se crea (consolidado en knowledge-graph.yaml)" \
    test ! -f "$TMP_TEST_DIR/.ai/memory/decisions-catalog.md"

assert_success ".gitignore y .gitattributes fueron configurados" \
    test -f "$TMP_TEST_DIR/.gitignore" -a -f "$TMP_TEST_DIR/.gitattributes"

# ------------------------------------------------------------------------------
# 2. Test new-initiative.sh
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}--- 2. Testing new-initiative.sh ---${NC}"

assert_success "new-initiative.sh crea una nueva feature FEAT-001" \
    bash "$SCRIPTS_DIR/new-initiative.sh" FEAT 001 user-auth

assert_success "FEAT-001 contiene spec.md y decision.md" \
    test -f "$TMP_TEST_DIR/.ai/features/FEAT-001-user-auth/spec.md" -a -f "$TMP_TEST_DIR/.ai/features/FEAT-001-user-auth/decision.md"

assert_success "FEAT-001 NO pre-crea archivos prematuros (ui-design, architecture, qa)" \
    test ! -f "$TMP_TEST_DIR/.ai/features/FEAT-001-user-auth/ui-design.md" -a \
         ! -f "$TMP_TEST_DIR/.ai/features/FEAT-001-user-auth/architecture.md" -a \
         ! -f "$TMP_TEST_DIR/.ai/features/FEAT-001-user-auth/qa.md"

assert_success "new-initiative.sh crea un bug BUG-001" \
    bash "$SCRIPTS_DIR/new-initiative.sh" BUG 001 db-timeout

assert_success "BUG-001 contiene bug-report.md y no pre-crea qa.md" \
    test -f "$TMP_TEST_DIR/.ai/features/BUG-001-db-timeout/bug-report.md" -a \
         ! -f "$TMP_TEST_DIR/.ai/features/BUG-001-db-timeout/qa.md"

assert_failure "new-initiative.sh rechaza IDs o tipos inválidos" \
    bash "$SCRIPTS_DIR/new-initiative.sh" INVALID 001 slug

assert_failure "new-initiative.sh rechaza ID no numérico" \
    bash "$SCRIPTS_DIR/new-initiative.sh" FEAT abc slug

# ------------------------------------------------------------------------------
# 3. Test finish-phase.sh
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}--- 3. Testing finish-phase.sh ---${NC}"

assert_success "finish-phase.sh cierra fase spec para FEAT-001" \
    bash "$SCRIPTS_DIR/finish-phase.sh" FEAT-001 spec analyst \
        --model "claude-3-7-sonnet" --provider "claude-code" \
        --tokens-in 3500 --tokens-out 1200 --duration 14 --source measured \
        --note "Especificación funcional completada"

assert_success "workflow-log.md registró la entrada de FEAT-001" \
    grep -q "## \[FEAT-001\]" "$TMP_TEST_DIR/.ai/memory/workflow-log.md"

assert_success "executions.yaml registró la telemetría" \
    grep -q "tokens_in: 3500" "$TMP_TEST_DIR/.ai/metrics/executions.yaml"

assert_success "aggregates.yaml fue regenerado" \
    test -f "$TMP_TEST_DIR/.ai/metrics/aggregates.yaml"

assert_success "context-snapshot.md fue regenerado con datos reales" \
    grep -q "FEAT-001" "$TMP_TEST_DIR/.ai/memory/context-snapshot.md"

# ------------------------------------------------------------------------------
# 4. Test validate-project.sh
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}--- 4. Testing validate-project.sh ---${NC}"

assert_success "validate-project.sh valida exitosamente el proyecto en progreso" \
    bash "$SCRIPTS_DIR/validate-project.sh"

# Test de fallo: crear una carpeta con nombre inválido
mkdir -p "$TMP_TEST_DIR/.ai/features/INVALID_FOLDER_NAME"
assert_failure "validate-project.sh falla si hay una carpeta con nombre inválido" \
    bash "$SCRIPTS_DIR/validate-project.sh"
rm -rf "$TMP_TEST_DIR/.ai/features/INVALID_FOLDER_NAME"

# ------------------------------------------------------------------------------
# 5. Test archive-initiative.sh
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}--- 5. Testing archive-initiative.sh ---${NC}"

assert_failure "archive-initiative.sh bloquea el archivado si QA no está aprobado" \
    bash "$SCRIPTS_DIR/archive-initiative.sh" FEAT-001-user-auth

# Simular completitud y aprobación de QA
cat > "$TMP_TEST_DIR/.ai/features/FEAT-001-user-auth/architecture.md" << 'EOF'
# Diseño Técnico — FEAT-001-user-auth
Arquitectura validada.
EOF

cat > "$TMP_TEST_DIR/.ai/features/FEAT-001-user-auth/qa.md" << 'EOF'
# Reporte de QA — FEAT-001-user-auth
> **Veredicto:** APROBADO
EOF

assert_success "archive-initiative.sh archiva FEAT-001 tras QA Aprobado" \
    bash "$SCRIPTS_DIR/archive-initiative.sh" FEAT-001-user-auth --note "Deploy exitoso a producción"

assert_success "FEAT-001 ahora reside en .ai/archive/" \
    test -d "$TMP_TEST_DIR/.ai/archive/FEAT-001-user-auth" -a ! -d "$TMP_TEST_DIR/.ai/features/FEAT-001-user-auth"

# ------------------------------------------------------------------------------
# 6. Test sync-initiatives.sh
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}--- 6. Testing sync-initiatives.sh ---${NC}"

assert_success "sync-initiatives.sh reconcilia sin errores" \
    bash "$SCRIPTS_DIR/sync-initiatives.sh"

# ------------------------------------------------------------------------------
# 7. Test examples/golden-project/ Fixture Integrity
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}--- 7. Testing examples/golden-project/ ---${NC}"

assert_success "golden-project cuenta con estructura canónica completa" \
    test -d "$REPO_ROOT/examples/golden-project/.ai" -a \
         -f "$REPO_ROOT/examples/golden-project/.ai/context.md" -a \
         -f "$REPO_ROOT/examples/golden-project/.ai/knowledge-graph.yaml" -a \
         -d "$REPO_ROOT/examples/golden-project/.ai/archive/FEAT-001-user-auth" -a \
         -d "$REPO_ROOT/examples/golden-project/.ai/features/FEAT-002-order-checkout"

assert_success "validate-project.sh pasa al 100% (0 errores, 0 warnings) en golden-project" \
    bash -c "cd '$REPO_ROOT/examples/golden-project' && bash '$SCRIPTS_DIR/validate-project.sh'"

# ------------------------------------------------------------------------------
# Resumen Final
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}====================================================${NC}"
echo -e "${BLUE}   📊 Resumen de Resultados de la Suite            ${NC}"
echo -e "${BLUE}====================================================${NC}"
echo -e "Total Pruebas: $TOTAL_TESTS"
echo -e "Aprobadas:     ${GREEN}$PASSED_TESTS${NC}"
echo -e "Fallidas:      ${RED}$FAILED_TESTS${NC}"
echo -e "===================================================="

if [ "$FAILED_TESTS" -eq 0 ]; then
    echo -e "${GREEN}🎉 ¡Todas las pruebas pasaron exitosamente!${NC}"
    exit 0
else
    echo -e "${RED}❌ Se detectaron fallos en la suite de pruebas.${NC}"
    exit 1
fi
