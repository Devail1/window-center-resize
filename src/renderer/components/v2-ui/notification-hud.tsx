"use client"

import { useEffect } from "react"
import { Card } from "@/components/ui/card"
import { Check } from "lucide-react"

interface Notification {
  id: string
  message: string
  preset?: {
    name: string
    x: number
    y: number
    width: number
    height: number
    unit: string
  }
  timestamp: number
}

interface NotificationHUDProps {
  notifications: Notification[]
  onDismiss: (id: string) => void
}

export function NotificationHUD({ notifications, onDismiss }: NotificationHUDProps) {
  useEffect(() => {
    // Auto-dismiss notifications after 3 seconds
    const timers = notifications.map((notification) => setTimeout(() => onDismiss(notification.id), 3000))

    return () => {
      timers.forEach((timer) => clearTimeout(timer))
    }
  }, [notifications, onDismiss])

  if (notifications.length === 0) return null

  return (
    <div className="fixed top-4 right-4 z-50 space-y-2">
      {notifications.map((notification) => (
        <Card
          key={notification.id}
          className="p-3 bg-background/95 backdrop-blur border shadow-lg animate-in slide-in-from-right-full duration-300"
        >
          <div className="flex items-center gap-3">
            <div className="flex h-8 w-8 items-center justify-center rounded-full bg-green-100 dark:bg-green-900/20">
              <Check className="h-4 w-4 text-green-600" />
            </div>

            <div className="flex-1 space-y-1">
              <p className="text-sm font-medium">{notification.message}</p>

              {notification.preset && (
                <div className="flex items-center gap-2">
                  <div className="relative w-12 h-8 bg-muted rounded border overflow-hidden">
                    <div className="absolute inset-0.5 bg-background rounded">
                      <div
                        className="absolute bg-primary/40 border border-primary/60 rounded"
                        style={{
                          left: `${notification.preset.x * 0.12}px`,
                          top: `${notification.preset.y * 0.08}px`,
                          width: `${notification.preset.width * 0.12}px`,
                          height: `${notification.preset.height * 0.08}px`,
                        }}
                      />
                    </div>
                  </div>

                  <div className="text-xs text-muted-foreground">
                    {Math.round(notification.preset.width)}×{Math.round(notification.preset.height)}{" "}
                    {notification.preset.unit}
                  </div>
                </div>
              )}
            </div>

            <button
              onClick={() => onDismiss(notification.id)}
              className="text-muted-foreground hover:text-foreground transition-colors"
            >
              <Check className="h-4 w-4" />
            </button>
          </div>
        </Card>
      ))}
    </div>
  )
}
