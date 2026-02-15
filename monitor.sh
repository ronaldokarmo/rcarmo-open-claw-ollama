#!/bin/bash
echo "📊 Monitoramento OpenClaw"
echo "========================"

# Status do container
docker ps --filter "name=openclaw" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "🧠 Uso de Recursos:"
docker stats openclaw --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}"

echo ""
echo "📈 Logs Recentes:"
docker logs openclaw --tail 10 --timestamps

echo ""
echo "🔌 Conexões Ativas:"
docker exec openclaw netstat -tuln | grep LISTEN
